class ReshapePaypalRefund < ActiveRecord::Migration
  def change
  	add_column :paypal_refunds, :status, :string, limit: 64, null: false
  	add_column :paypal_refunds, :status_reason, :string, limit: 64
  	remove_column :paypal_refunds, :refunding_id
  	rename_column :paypal_refunds, :payment_total_cents, :refund_total_cents
  	add_column :paypal_refunds, :ext_refund_transaction_id, :integer
  	add_column :paypal_refunds, :receiver_id, :string, null: false, limit: 64
  	add_column :paypal_refunds, :refunder_id, :string, null: false, limit: 64
  end
end
