class RemoveRefundFields < ActiveRecord::Migration
  def change
  	remove_column :paypal_refunds, :receiver_id, :integer
  	remove_column :paypal_refunds, :refunder_id, :integer
  	remove_column :paypal_refunds, :ext_refund_transaction_id, :integer
  	add_column    :paypal_refunds, :ext_refund_transaction_id, :string
  end
end
