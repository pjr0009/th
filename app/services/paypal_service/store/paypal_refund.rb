module PaypalService::Store::PaypalRefund
  PaypalRefundModel = ::PaypalRefund
  PaypalPaymentModel = ::PaypalPayment
  
  InitialRefundData = EntityUtils.define_builder(
    [:paypal_payment_id, :mandatory, :fixnum],
    [:refund_total, :money],
    [:ext_refund_transaction_id, :string],
    [:status, :mandatory, :string]
  )


  PaypalRefund = EntityUtils.define_builder(
    [:paypal_payment_id, :mandatory, :fixnum],
    [:refund_total, :money],
    [:ext_refund_transaction_id, :string],
    [:status, :mandatory, :string],
    [:status_reason, :string]
  )

  module_function

  def from_model(paypal_refund)
    hash = HashUtils.compact(
      EntityUtils.model_to_hash(paypal_refund).merge({
          refund_total: MoneyUtil.to_money(paypal_refund.refund_total_cents, paypal_refund.currency)
        }))

    PaypalRefund.call(hash)
  end

  def create(refund)
    model = PaypalRefundModel.create!(InitialRefundData.call(refund))
    from_model(model)
  end

  def get(paypal_payment_id)
    PaypalRefundModel.find_by(:paypal_payment_id => paypal_payment_id)
  end

end

