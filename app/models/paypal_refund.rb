# == Schema Information
#
# Table name: paypal_refunds
#
#  id                        :integer          not null, primary key
#  paypal_payment_id         :integer
#  currency                  :string(8)
#  refund_total_cents        :integer
#  fee_total_cents           :integer
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  status                    :string(64)       not null
#  status_reason             :string(64)
#  ext_refund_transaction_id :string(255)
#

class PaypalRefund < ActiveRecord::Base
  attr_accessible :paypal_payment_id, :currency, :refund_total_cents, :refund_total, :receiver_id, :refunder_id, :status, :status_reason, :ext_refund_transaction_id

  monetize :refund_total_cents, with_model_currency: :currency, allow_nil: true

end
