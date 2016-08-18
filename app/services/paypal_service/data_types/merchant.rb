module PaypalService
  module DataTypes

    module Merchant

      SetupBillingAgreement = EntityUtils.define_builder(
        [:method, const_value: :setup_billing_agreement],
        [:description, :mandatory, :string],
        [:success, :mandatory, :string],
        [:cancel, :mandatory, :string])

      SetupBillingAgreementResponse = EntityUtils.define_builder(
        [:success, const_value: true],
        [:token, :mandatory, :string],
        [:redirect_url, :mandatory, :string],
        [:username_to, :mandatory, :string])

      CreateBillingAgreement = EntityUtils.define_builder(
        [:method, const_value: :create_billing_agreement],
        [:token, :mandatory, :string])

      CreateBillingAgreementResponse = EntityUtils.define_builder(
        [:success, const_value: true],
        [:billing_agreement_id, :mandatory, :string])

      DoReferenceTransaction = EntityUtils.define_builder(
        [:method, const_value: :do_reference_transaction],
        [:receiver_username, :mandatory, :string],
        [:billing_agreement_id, :mandatory, :string],
        [:payment_total, :mandatory, :money],
        [:name, :string, :mandatory],
        [:desc, :string],
        [:invnum, :string, :mandatory], # Unique tx id on our side
        [:msg_sub_id, transform_with: -> (v) { v.nil? ? SecureRandom.uuid : v }])

      DoReferenceTransactionResponse = EntityUtils.define_builder(
        [:success, const_value: true],
        [:billing_agreement_id, :mandatory, :string],
        [:payment_status, :mandatory, :string],
        [:pending_reason, :string],
        [:payment_id, :mandatory, :string],
        [:payment_total, :mandatory, :money],
        [:payment_date, :utc_str_to_time],
        [:fee, :money],
        [:username_to, :mandatory, :string])

      GetChainedPaymentDetails = EntityUtils.define_builder(
        [:method, const_value: :get_chained_payment_details],
        [:receiver_username, :optional, :string],
        [:token, :mandatory, :string])


      GetChainedPaymentDetailsResponse = EntityUtils.define_builder(
        [:success, const_value: true],
        [:token, :mandatory, :string],
        [:payment_status, :mandatory, :string],
        [:payer, :string],
        [:payer_id, :string],
        [:order_total, :money],
        [:shipping_address_status, :string],
        [:shipping_address_city, :string],
        [:shipping_address_country, :string],
        [:shipping_address_country_code, :string],
        [:shipping_address_name, :string],
        [:shipping_address_phone, :string],
        [:shipping_address_postal_code, :string],
        [:shipping_address_state_or_province, :string],
        [:shipping_address_street1, :string],
        [:shipping_address_street2, :string])

      # Deprecated - Order flow will be removed soon
      #
      SetExpressCheckoutOrder = EntityUtils.define_builder(
        [:method, const_value: :set_express_checkout_order],
        [:item_name, :mandatory, :string],
        [:item_quantity, :fixnum, default: 1],

        [:require_shipping_address, :to_bool],
        [:item_price, :mandatory, :money],

        # If specified, require_shipping_address must be true
        [:shipping_total, :optional],

        # Must match item_price * item_quantity + shipping_total
        [:order_total, :mandatory, :money],

        [:receiver_username, :mandatory, :string],
        [:success, :mandatory, :string],
        [:cancel, :mandatory, :string],
        [:invnum, :mandatory, :string],
        [:merchant_brand_logo_url, :optional, :string])

      SetExpressCheckoutOrderResponse = EntityUtils.define_builder(
        [:success, const_value: true],
        [:token, :mandatory, :string],
        [:redirect_url, :mandatory, :string],
        [:receiver_username, :mandatory, :string])
      #
      # /Deprecated

      SetExpressCheckoutAuthorization = EntityUtils.define_builder(
        [:method, const_value: :set_express_checkout_authorization],
        [:item_name, :mandatory, :string],
        [:item_quantity, :fixnum, default: 1],

        [:require_shipping_address, :to_bool],
        [:item_price, :mandatory, :money],

        # If specified, require_shipping_address must be true
        [:shipping_total, :optional],

        # Must match item_price * item_quantity + shipping_total
        [:order_total, :mandatory, :money],

        [:receiver_username, :mandatory, :string],
        [:success, :mandatory, :string],
        [:cancel, :mandatory, :string],
        [:invnum, :mandatory, :string],
        [:merchant_brand_logo_url, :optional, :string])

      CreateChainedPayment = EntityUtils.define_builder(
        [:method, const_value: :create_chained_payment],
        [:item_name, :mandatory, :string],
        [:item_quantity, :fixnum, default: 1],

        [:require_shipping_address, :to_bool],
        [:item_price, :mandatory, :money],

        # If specified, require_shipping_address must be true
        [:shipping_total, :optional],

        # Must match item_price * item_quantity + shipping_total
        [:order_total, :mandatory, :money],
        [:success, :mandatory, :string],
        [:cancel, :mandatory, :string],
        [:payer_id, :mandatory, :string],
        [:invnum, :mandatory, :string],
        [:merchant_brand_logo_url, :optional, :string])
      
      CreateChainedPaymentResponse = EntityUtils.define_builder(
        [:success, const_value: true],
        [:token, :mandatory, :string],
        [:redirect_url, :mandatory, :string],
        [:receiver_username, :mandatory, :string])

      SetPaymentOptions = EntityUtils.define_builder(
        [:method, const_value: :set_payment_options],
        [:token, :mandatory, :string]        
      )

      SetPaymentOptionsResponse = EntityUtils.define_builder(
        [:success, const_value: true]
      )

      SetExpressCheckoutAuthorizationResponse = EntityUtils.define_builder(
        [:success, const_value: true],
        [:token, :mandatory, :string],
        [:redirect_url, :mandatory, :string],
        [:receiver_username, :mandatory, :string])

      DoVoid = EntityUtils.define_builder(
        [:method, const_value: :do_void],
        [:receiver_username, :mandatory, :string],
        [:transaction_id, :mandatory, :string], # To void an order pass order_id. To void an authorization pass authorization_id
        [:note, :string],
        [:msg_sub_id, transform_with: -> (v) { v.nil? ? SecureRandom.uuid : v }])

      DoVoidResponse = EntityUtils.define_builder(
        [:success, const_value: true],
        [:voided_id, :mandatory, :string],
        [:msg_sub_id, :string])

      RefundTransaction = EntityUtils.define_builder(
        [:method, const_value: :refund_transaction],
        [:receiver_username, :mandatory, :string],
        [:payment_id, :string, :mandatory],
        [:msg_sub_id, transform_with: -> (v ) { v.nil? ? SecureRandom.uuid : v }])

      RefundTransactionResponse = EntityUtils.define_builder(
        [:success, const_value: true],
        [:refunded_id, :mandatory, :string],
        [:refunded_fee_total, :mandatory, :money],
        [:refunded_net_total, :mandatory, :money],
        [:refunded_gross_total, :mandatory, :money],
        [:refunded_total, :mandatory, :money],
        [:msg_sub_id, :string])

      GetTransactionDetails = EntityUtils.define_builder(
        [:method, const_value: :get_transaction_details],
        [:receiver_username, :mandatory, :string],
        [:transaction_id, :mandatory, :string])

      GetTransactionDetailsResponse = EntityUtils.define_builder(
        [:success, const_value: true],
        [:transaction_id, :mandatory, :string],
        [:payment_status, :mandatory, :string],
        [:pending_reason, :string],
        [:transaction_total, :money])


      module_function

      def create_setup_billing_agreement(opts); SetupBillingAgreement.call(opts) end
      def create_setup_billing_agreement_response(opts); SetupBillingAgreementResponse.call(opts) end

      def create_create_billing_agreement(opts); CreateBillingAgreement.call(opts) end
      def create_create_billing_agreement_response(opts); CreateBillingAgreementResponse.call(opts) end

      def create_do_reference_transaction(opts); DoReferenceTransaction.call(opts) end
      def create_do_reference_transaction_response(opts); DoReferenceTransactionResponse.call(opts) end

      def create_get_chained_payment_details(opts); GetChainedPaymentDetails.call(opts) end
      def create_get_chained_payment_details_response(opts); GetChainedPaymentDetailsResponse.call(opts) end

      def create_chained_payment(opts); CreateChainedPayment.call(opts) end
      def create_chained_payment_response(opts); CreateChainedPaymentResponse.call(opts) end
      def set_payment_options(opts); SetPaymentOptions.call(opts) end
      def set_payment_options_response(opts); SetPaymentOptionsResponse.call(opts) end

      def create_set_express_checkout_order(opts); SetExpressCheckoutOrder.call(opts) end
      def create_set_express_checkout_order_response(opts); SetExpressCheckoutOrderResponse.call(opts) end

      def create_set_express_checkout_authorization(opts); SetExpressCheckoutAuthorization.call(opts) end
      def create_set_express_checkout_authorization_response(opts); SetExpressCheckoutAuthorizationResponse.call(opts) end

      def create_do_void(opts); DoVoid.call(opts) end
      def create_do_void_response(opts); DoVoidResponse.call(opts) end

      def create_refund_transaction(opts); RefundTransaction.call(opts) end
      def create_refund_transaction_response(opts); RefundTransactionResponse.call(opts) end

      def create_get_transaction_details(opts); GetTransactionDetails.call(opts) end
      def create_get_transaction_details_response(opts); GetTransactionDetailsResponse.call(opts) end

    end

  end
end
