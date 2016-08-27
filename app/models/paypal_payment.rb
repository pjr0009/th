# == Schema Information
#
# Table name: paypal_payments
#
#  id                  :integer          not null, primary key
#  community_id        :integer          not null
#  transaction_id      :integer          not null
#  payer_id            :string(64)       not null
#  receiver_id         :string(64)       not null
#  merchant_id         :string(255)      not null
#  ext_transaction_id  :string(64)
#  payment_date        :datetime
#  currency            :string(8)        not null
#  payment_total_cents :integer
#  fee_total_cents     :integer
#  payment_status      :string(64)       not null
#  pending_reason      :string(64)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  token               :string(255)
#
# Indexes
#
#  index_paypal_payments_on_community_id        (community_id)
#  index_paypal_payments_on_ext_transaction_id  (ext_transaction_id) UNIQUE
#  index_paypal_payments_on_transaction_id      (transaction_id) UNIQUE
#

class PaypalPayment < ActiveRecord::Base
  attr_accessible(
    :community_id,
    :transaction_id,
    :payer_id,
    :receiver_id,
    :merchant_id,
    :currency,
    :ext_transaction_id,
    :payment_date,
    :payment_total_cents,
    :fee_total_cents,
    :payment_status,
    :pending_reason,
    :token)

  validates_presence_of(
    :community_id,
    :transaction_id,
    :ext_transaction_id,
    :payer_id,
    :token,
    :receiver_id,
    :currency,
    :payment_status)

  monetize :payment_total_cents,        with_model_currency: :currency, allow_nil: false
  monetize :fee_total_cents,            with_model_currency: :currency, allow_nil: true
end
