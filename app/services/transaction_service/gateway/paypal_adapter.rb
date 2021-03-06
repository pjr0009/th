module TransactionService::Gateway
  class PaypalAdapter < GatewayAdapter

    DataTypes = PaypalService::API::DataTypes

    def implements_process(process)
      [:none, :preauthorize].include?(process)
    end

    def create_payment(tx:, gateway_fields:, prefer_async:)
      # Note: Quantity may be confusing in Paypal Checkout page, thus,
      # we don't use separated unit price and quantity, only the total
      # price for now.
      shipping_total = Maybe(tx[:shipping_price]).or_else(0)
      payment_total = tx[:unit_price] * tx[:listing_quantity] + shipping_total
      #define base payment creation params
      payment_params = {
         transaction_id: tx[:id],
         item_name: tx[:listing_title],
         item_quantity: tx[:listing_quantity],
         item_price: tx[:unit_price],
         merchant_id: tx[:listing_author_id],
         shipping_total: tx[:shipping_price],
         payment_total: payment_total,
         memo: tx[:listing_title],
         success: gateway_fields[:success_url],
         cancel: gateway_fields[:cancel_url],
         delivery_method: tx[:delivery_method],
         merchant_brand_logo_url: gateway_fields[:merchant_brand_logo_url]
      }
      if tx[:delivery_method] == :shipping
        payment_params[:memo] = tx[:listing_title] + " + #{tx[:shipping_price]} shipping"
        
        #augment with shipping address and new memo if shipped item
        payment_params.merge!({
          shipping_address_street1: tx[:shipping_address][:street1],
          shipping_address_street2: tx[:shipping_address][:street2],
          shipping_address_city: tx[:shipping_address][:city],
          shipping_address_state_or_province: tx[:shipping_address][:state_or_province],
          shipping_address_name: tx[:shipping_address][:name],
          shipping_address_phone: tx[:shipping_address][:phone],
          shipping_address_postal_code: tx[:shipping_address][:postal_code]
        })
        create_payment_info = DataTypes.create_create_shipping_payment_request(payment_params)

      else
        create_payment_info = DataTypes.create_create_pickup_payment_request(payment_params)
      end

      result = paypal_api.payments.request(
        tx[:community_id],
        create_payment_info,
        async: prefer_async)

      unless result[:success]
        return SyncCompletion.new(result)
      end

      if prefer_async
        AsyncCompletion.new(Result::Success.new({ process_token: result[:data][:process_token] }))
      else
        AsyncCompletion.new(Result::Success.new({ redirect_url: result[:data][:redirect_url] }))
      end
    end

    def reject_payment(tx:, reason: "")
      AsyncCompletion.new(paypal_api.payments.void(tx[:community_id], tx[:id], {note: reason}))
    end

    def complete_preauthorization(tx:)
      # AsyncCompletion.new(
      #   paypal_api.payments.get_payment(tx[:community_id], tx[:id])
      #   .and_then { |payment|
      #     paypal_api.payments.full_capture(
      #       tx[:community_id],
      #       tx[:id],
      #       DataTypes.create_payment_info({ payment_total: payment[:authorization_total] }))
      #   })
    end

    def get_payment_details(tx:)
      payment = paypal_api.payments.get_payment(tx[:community_id], tx[:id]).maybe

      payment_total = payment[:payment_total].or_else(nil)
      total_price = Maybe(payment[:payment_total].or_else(nil))
                    .or_else(tx[:unit_price])

      { payment_total: payment_total,
        total_price: total_price,
        charged_commission: payment[:commission_total].or_else(nil),
        payment_gateway_fee: payment[:fee_total].or_else(nil) }
    end


    def refund(tx:, prefer_async:)
      payment = paypal_api.payments.get_payment(tx[:community_id], tx[:id])[:data]

      refund_info = DataTypes.create_refund_request(
        {
         transaction_id: tx[:id],
         paypal_payment_id: payment[:id],
         ext_transaction_id: payment[:ext_transaction_id],
         refund_total: payment[:payment_total],
         token: payment[:token],
         })

      result = paypal_api.payments.refund(
        tx[:community_id],
        refund_info,
        async: prefer_async)

      unless result[:success]
        return SyncCompletion.new(result)
      end

      if prefer_async
        AsyncCompletion.new(Result::Success.new({ process_token: result[:data][:process_token] }))
      else
        AsyncCompletion.new(Result::Success.new({ redirect_url: result[:data][:redirect_url] }))
      end
    end



    private

    def paypal_api
      PaypalService::API::Api
    end
  end

end
