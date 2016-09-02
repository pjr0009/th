module PaypalService::API

  class Payments

    # Include with_success for wrapping requests and responses
    include RequestWrapper

    attr_reader :logger

    MerchantData = PaypalService::DataTypes::Merchant
    TokenStore = PaypalService::Store::Token
    PaymentStore = PaypalService::Store::PaypalPayment
    RefundStore = PaypalService::Store::PaypalRefund
    Lookup = PaypalService::API::Lookup
    Worker = PaypalService::API::Worker
    Invnum = PaypalService::API::Invnum
    APIDataTypes = PaypalService::API::DataTypes

    def initialize(events, merchant, logger = PaypalService::Logger.new)
      @logger = logger
      @events = events
      @merchant = merchant
      @lookup = Lookup.new(logger)
    end

    # For RequestWrapper mixin
    def paypal_merchant
      @merchant
    end


    # The API implementation
    #

    ## POST /payments/request
    def request(community_id, create_payment, async: false)
      @lookup.with_active_account(
        community_id, create_payment[:merchant_id]
      ) do |m_acc|
        if (async)
          proc_token = Worker.enqueue_payments_op(
            community_id: community_id,
            transaction_id: create_payment[:transaction_id],
            op_name: :do_request,
            op_input: [community_id, create_payment, m_acc])

          proc_status_response(proc_token)
        else
          do_request(community_id, create_payment, m_acc)
        end
      end
    end

    def do_request(community_id, create_payment, m_acc)
      #IMPORTANT PAYER_ID IS A PAYPAL SPECIFIC TERM, REFERRING TO THEIR PAYPAL UUID
      create_payment_data = create_payment.merge(
        { payer_id: m_acc[:payer_id],
          invnum: Invnum.create(community_id, create_payment[:transaction_id], :payment)})
     
      request = MerchantData.create_chained_payment(create_payment_data)
      with_success(community_id, create_payment[:transaction_id],
        request,
        error_policy: {
          codes_to_retry: ["10001", "x-timeout", "x-servererror"],
          try_max: 3
        }
      ) do |response|
        #set payment options for checkout, not super critical so ill unwrap it from all of the cumbersome retry / callback stuff
        set_payment_options_request = MerchantData.set_payment_options({
          token: response[:token], 
          payer_id: m_acc[:payer_id], 
          shipping_total: create_payment[:shipping_total], 
          item_price: create_payment[:item_price],
          item_name: create_payment[:item_name]
        })
        @merchant.do_request(set_payment_options_request)


        #create paypal token
        TokenStore.create({
          community_id: community_id,
          token: response[:token],
          transaction_id: create_payment[:transaction_id],
          merchant_id: m_acc[:person_id],
          receiver_id: m_acc[:payer_id],
          item_name: create_payment[:item_name],
          item_quantity: create_payment[:item_quantity],
          item_price: create_payment[:item_price] || create_payment[:order_total],
          shipping_total: create_payment[:shipping_total],
          paypal_redirect_url: response[:redirect_url]
        })

        Result::Success.new(
          APIDataTypes.create_payment_request({
              transaction_id: create_payment[:transaction_id],
              token: response[:token],
              redirect_url: response[:redirect_url]}))
      end
    end

    def set_payment_info
      Worker.enqueue_payments_op(
            community_id: community_id,
            transaction_id: create_payment[:transaction_id],
            op_name: :do_request,
            op_input: [community_id, create_payment, m_acc])
    end


    def get_request_token(community_id, token)
      @lookup.with_token(community_id, token) do |token|
        Result::Success.new(token)
      end
    end

    ## POST /payments/request/cancel?token=EC-7XU83376C70426719
    def request_cancel(community_id, token_id)
      token = TokenStore.get(community_id, token_id)
      unless (token.nil?)
        TokenStore.delete(community_id, token[:transaction_id])

        #trigger callback for request cancelled
        @events.send(:request_cancelled, :success, token)

        Result::Success.new
      else
        #Handle errors by logging, because request cancellations are async (direct cancels + scheduling)
        @logger.warn("Tried to cancel non-existent request: [token: #{token_id}, community: #{community_id}]")
        Result::Error.new("Tried to cancel non-existent request: [token: #{token_id}, community: #{community_id}]")
      end
    end

    ## POST /payments/:community_id/create?token=EC-7XU83376C70426719
    def create(community_id, token, async: false)
      @lookup.with_token(community_id, token) do |token|
        if (async)
          proc_token = Worker.enqueue_payments_op(
            community_id: community_id,
            transaction_id: token[:transaction_id],
            op_name: :do_create,
            op_input: [community_id, token])

          proc_status_response(proc_token)
        else
          do_create(community_id, token)
        end
      end
    end

    def do_create(community_id, token)
      existing_payment = @lookup.get_payment_by_token(token)

      response =
        if existing_payment.nil?
          create_payment(token)
            .and_then { |payment_entity| Result::Success.new(payment_entity) }
        else
          Result::Success.new(existing_payment)
        end

      if response.success
        # Delete the token, we have now completed the payment request
        # execute_payment_request = MerchantData.execute_payment({token: response[:token]})
        # @merchant.do_request(execute_payment_request)
        TokenStore.delete(community_id, response[:data][:transaction_id])
      end

      response
    end

    ## GET /payments/:community_id/:transaction_id
    def get_payment(community_id, transaction_id)
      Maybe(PaymentStore.get(community_id, transaction_id))
        .map { |payment| Result::Success.new(APIDataTypes.create_payment(payment)) }
        .or_else { Result::Error.new("No matching payment for community_id: #{community_id} and transaction_id: #{transaction_id}.")}
    end

    ## POST /payments/:community_id/:transaction_id/void
    def void(community_id, transaction_id, info, async: false)
      @lookup.with_payment(community_id, transaction_id, [[:pending, nil]]) do |payment, m_acc|
        if (async)
          proc_token = Worker.enqueue_payments_op(
            community_id: community_id,
            transaction_id: transaction_id,
            op_name: :do_void,
            op_input: [community_id, transaction_id, info, payment, m_acc])

          proc_status_response(proc_token)
        else
          do_void(community_id, transaction_id, info, payment, m_acc)
        end
      end
    end

    def do_void(community_id, transaction_id, info, payment, m_acc)
      void_payment(
        community_id,
        transaction_id,
        payment,
        :success,
        m_acc,
        info[:note])
    end

    ## POST /payments/:community_id/create?token=EC-7XU83376C70426719
    def refund(community_id, refund_info, async: false)
      if (async)
        proc_token = Worker.enqueue_payments_op(
          community_id: community_id,
          transaction_id: refund_info[:transaction_id],
          op_name: :do_refund,
          op_input: [community_id, refund_info]
        )

        proc_status_response(proc_token)
      else
        do_refund(community_id, refund_info)
      end
    end

    def do_refund(community_id, refund_info)
      # Send event payment_crated
      existing_refund = @lookup.get_refund_by_payment_id(refund_info[:paypal_payment_id])
      if existing_refund.nil?
        refund = RefundStore.create(refund_info)

        request = MerchantData.create_refund_paypal_payment(refund_info)
   
        with_success(community_id, refund_info[:transaction_id],
          request,
          error_policy: {
            codes_to_retry: ["10001", "x-timeout", "x-servererror"],
            try_max: 3
          }
        ) do |response|
          response.merge!({paypal_payment_id: refund_info[:paypal_payment_id], transaction_id: refund_info[:transaction_id]})

          @events.send(:payment_refunded, :success, response)

          
          Result::Success.new(response)
        end
      else
        Result::Success.new(existing_refund)
      end 
    end

    ## Not part of the public API, used by rake task to retry and clean unfinished orders
    def retry_and_clean_tokens(clean_time_limit)
      TokenStore.get_all.each do |token|
        response = create(token.community_id, token.token)

        if(!response[:success] && stop_retrying_token?(response, token.created_at, clean_time_limit))
          request_cancel(token.community_id, token.token)
        end
      end
    end


    private


    # Reusable bits of the API operations
    #

    def stop_retrying_token?(response, token_created_at, clean_time_limit)
      if (token_created_at < clean_time_limit && (response[:data] == nil || response[:data][:error_code] != :"payment-review"))
        true
      else
        false
      end
    end

    def create_payment(token)
      #find the merchant account via the token, then use the merchant account payer id
      #to create the request that gets the payment details
      @lookup.with_merchant_account(token[:community_id], token) do |m_acc|
        with_success(token[:community_id], token[:transaction_id],
          MerchantData.create_get_chained_payment_details(
            { receiver_username: m_acc[:payer_id], token: token[:token] }
          ),
          error_policy: {
            codes_to_retry: ["10001", "x-timeout", "x-servererror"],
            try_max: 3,
            finally: method(:handle_failed_create_payment).call(token),
          }
        ) do |ec_details|
          # Validate that the buyer accepted and we have a payer_id now
          if (ec_details[:payer_id].nil?)
            return Result::Error.new("Payment has not been accepted by the buyer.")
          end

          order_details = create_order_details(ec_details)
                          .merge({community_id: token[:community_id], transaction_id: token[:transaction_id]})

          #step 1) add this paypal info back to the transaction                
          @events.send(:augment_transaction_details_with_paypal_info, :success, order_details)
          # Save payment
          payment = PaymentStore.create(          
            token[:community_id],
            token[:transaction_id],
            ec_details
              .merge({merchant_id: m_acc[:person_id]})
          )

          payment_entity = APIDataTypes.create_payment(payment)

          # Send event payment_crated
          @events.send(:payment_created, :success, payment_entity)

          # Return as payment entity
          Result::Success.new(payment_entity)
        end
      end
    end

    def create_order_details(data)
      APIDataTypes.create_order_details(
        HashUtils.rename_keys({
          shipping_address_status: :status,
          shipping_address_city: :city,
          shipping_address_country: :country,
          shipping_address_country_code: :country_code,
          shipping_address_name: :name,
          shipping_address_phone: :phone,
          shipping_address_postal_code: :postal_code,
          shipping_address_state_or_province: :state_or_province,
          shipping_address_street1: :street1,
          shipping_address_street2: :street2,
        }, data))
    end

    def void_payment(community_id, transaction_id, payment, flow, m_acc, note = nil)
      with_success(community_id, transaction_id,
        MerchantData.create_do_void({
            receiver_username: m_acc[:payer_id],

            # Void order if it exists, it automatically voids any
            # authorization connected to the payment but with auth
            # flow we have no order so void the authorization
            # directly.
            transaction_id: payment[:order_id] ? payment[:order_id] : payment[:authorization_id],
            note: note
          }),
        error_policy: {
          codes_to_retry: ["10001", "x-timeout", "x-servererror"],
          try_max: 5
        }
        ) do |void_res|
        with_success(community_id, transaction_id, MerchantData.create_get_transaction_details({
              receiver_username: m_acc[:payer_id],
              transaction_id: payment[:order_id] ? payment[:order_id] : payment[:authorization_id],
            })) do |payment_res|
          payment = PaymentStore.update(
            data: payment_res,
            community_id: community_id,
            transaction_id: transaction_id)

          payment_entity = APIDataTypes.create_payment(payment)

          # Trigger payment_updated
          @events.send(:payment_updated, flow, payment_entity)

          Result::Success.new(payment_entity)
        end
      end
    end

    def proc_status_response(proc_token)
      Result::Success.new(
        APIDataTypes.create_process_status({
            process_token: proc_token[:process_token],
            completed: proc_token[:op_completed],
            result: proc_token[:op_output]}))
    end


    # Error handlers
    #

    def handle_failed_create_payment(token)
      -> (cid, txid, request, err_response) do
        data =
          if err_response[:error_code] == "10486"
            {redirect_url: token[:paypal_redirect_url]}
          elsif ["10485", "13116"].include?(err_response[:error_code])
            # 10485 = Payment not authorized, meaning user logged in
            # at PayPal but didn't press Pay yet.
            #
            # 13116 = Payment in progress, we already made an API call
            # to complete the authorization.
            #
            # Do not cancel token yet if the user is in the middle of
            # authenticating / paying. Retry tokens logic might try
            # completing the payment in this phase and we don't want
            # that to trigger token cancellation.
            nil
          else
            request_cancel(cid, token[:token])
            nil
          end

        log_and_return(cid, txid, request, err_response, data || {})
      end
    end

    def handle_failed_authorization(payment, m_acc)
      -> (cid, txid, request, err_response) do
        if err_response[:error_code] == "10486"
          # Special handling for 10486 error. Return error response and do NOT void.
          token = PaypalService::Store::Token.get_for_transaction(payment[:community_id], payment[:transaction_id])
          redirect_url = append_order_id(remove_token(token[:paypal_redirect_url]), payment[:order_id])
          log_and_return(cid, txid, request, err_response, {redirect_url: "#{redirect_url}"})
        else
          void_failed_payment(payment, m_acc).call(payment[:community_id], payment[:transaction_id], request, err_response)
        end
      end
    end

    def void_failed_payment(payment, m_acc)
      -> (cid, txid, request, err_response) do
        void_payment(cid, txid, payment, :error, m_acc)

        # Return original error
        log_and_return(cid, txid, request, err_response)
      end
    end

    def append_order_id(url_str, order_id)
      URLUtils.append_query_param(url_str, "order_id", order_id)
    end

    def remove_token(url_str)
      URLUtils.remove_query_param(url_str, "token")
    end

  end
end
