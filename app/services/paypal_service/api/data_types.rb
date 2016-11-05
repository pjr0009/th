module PaypalService::API::DataTypes

  CreateShippingPaymentRequest = EntityUtils.define_builder(
    [:transaction_id, :mandatory, :fixnum],
    [:delivery_method, :to_symbol, :mandatory, one_of: [:none, :shipping, :pickup], default: :none],
    [:item_name, :mandatory, :string],
    [:item_quantity, :fixnum, default: 1],
    [:item_price, :mandatory, :money],
    [:merchant_id, :mandatory, :string],
    [:payment_total, :mandatory, :money],
    [:shipping_total, :money],
    [:shipping_address_street1, :mandatory, :string],
    [:shipping_address_street2, :string],
    [:shipping_address_city, :mandatory, :string],
    [:shipping_address_postal_code, :mandatory, :string],
    [:shipping_address_phone, :mandatory, :string],
    [:shipping_address_state_or_province, :mandatory, :string],
    [:shipping_address_name, :mandatory, :string],
    [:memo, :mandatory, :string],
    [:merchant_brand_logo_url, :string, :optional],
    [:success, :mandatory, :string],
    [:cancel, :mandatory, :string]
  )

  CreatePickupPaymentRequest = EntityUtils.define_builder(
    [:transaction_id, :mandatory, :fixnum],
    [:delivery_method, :to_symbol, :mandatory, one_of: [:none, :shipping, :pickup], default: :none],
    [:item_name, :mandatory, :string],
    [:item_quantity, :fixnum, default: 1],
    [:item_price, :mandatory, :money],
    [:merchant_id, :mandatory, :string],
    [:payment_total, :mandatory, :money],
    [:memo, :mandatory, :string],
    [:merchant_brand_logo_url, :string, :optional],
    [:success, :mandatory, :string],
    [:cancel, :mandatory, :string]
  )


  # Reponse for get_request_token is a PaypalService::Store::Token::Entity.Token

  PaymentRequest = EntityUtils.define_builder(
    [:transaction_id, :mandatory, :fixnum],
    [:token, :mandatory, :string],
    [:redirect_url, :mandatory, :string]
  )

  Payment = EntityUtils.define_builder(
    [:id, :fixnum],
    [:transaction_id, :mandatory, :fixnum],
    [:payer_id, :mandatory, :string],
    [:receiver_id, :mandatory, :string],
    [:merchant_id, :mandatory, :string],
    [:payment_status, one_of: [:pending, :completed, :refunded, :voided, :denied, :expired]],
    [:pending_reason, transform_with: -> (v) { (v.is_a? String) ? v.downcase.gsub("-", "").to_sym : v }],
    [:ext_transaction_id, :mandatory, :string],
    [:payment_date, :time],
    [:payment_total, :money],
    [:fee_total, :money],
    [:token, :string]
  )

  PaymentInfo = EntityUtils.define_builder(
    [:payment_total, :mandatory, :money]
  )

  CreateRefundRequest = EntityUtils.define_builder(
    [:paypal_payment_id, :mandatory, :fixnum],
    [:ext_transaction_id, :mandatory, :string],
    [:transaction_id, :mandatory, :fixnum],
    [:refund_total, :mandatory, :money],
    [:token, :mandatory, :string]
  )


  VoidingInfo = EntityUtils.define_builder([:note, :string])

  CommissionInfo = EntityUtils.define_builder(
    [:transaction_id, :mandatory, :fixnum],
    [:commission_total, :mandatory, :money],
    [:payment_name, :mandatory, :string],
    [:payment_desc, :string])

  ProcessStatus = EntityUtils.define_builder(
    [:process_token, :mandatory, :string],
    [:completed, :mandatory, :to_bool],
    [:result])

  CreateAccountRequest = EntityUtils.define_builder(
    [:person_id, :optional, :string],
    [:country, :mandatory, :string],
    [:callback_url, :mandatory, :string])

  AccountRequest = EntityUtils.define_builder(
    [:person_id, :optional, :string],
    [:redirect_url, :mandatory, :string],
    [:onboarding_params, :hash])

  AccountPermissionVerificationRequest = EntityUtils.define_builder(
    [:order_permission_verification_code, :string],
    [:onboarding_params, :hash])

  CreateBillingAgreementRequest = EntityUtils.define_builder(
    [:description, :mandatory, :string],
    [:success_url, :mandatory, :string],
    [:cancel_url, :mandatory, :string])

  BillingAgreementRequest = EntityUtils.define_builder(
    [:redirect_url, :mandatory, :string])

  OrderDetails = EntityUtils.define_builder(
    [:status, :string],
    [:city, :string],
    [:country, :string],
    [:country_code, :string],
    [:name, :string],
    [:phone, :string],
    [:postal_code, :string],
    [:state_or_province, :string],
    [:street1, :string],
    [:street2, :string])

  module_function

  def create_create_shipping_payment_request(opts); CreateShippingPaymentRequest.call(opts) end
  def create_create_pickup_payment_request(opts); CreatePickupPaymentRequest.call(opts) end
  def create_payment_request(opts); PaymentRequest.call(opts) end
  def create_refund_request(opts); CreateRefundRequest.call(opts) end
  def create_token_verification_info(opts); TokenVerificationInfo.call(opts) end
  def create_payment(opts); Payment.call(opts) end
  def create_payment_info(opts); PaymentInfo.call(opts) end
  def create_voiding_info(opts); VoidingInfo.call(opts) end
  def create_commission_info(opts); CommissionInfo.call(opts) end
  def create_process_status(opts); ProcessStatus.call(opts) end
  def create_create_account_request(opts); CreateAccountRequest.call(opts) end
  def create_account_request(opts); AccountRequest.call(opts) end
  def create_account_permission_verification_request(opts); AccountPermissionVerificationRequest.call(opts) end
  def create_create_billing_agreement_request(opts); CreateBillingAgreementRequest.call(opts) end
  def create_billing_agreement_request(opts); BillingAgreementRequest.call(opts) end
  def create_order_details(opts); OrderDetails.call(opts) end

end
