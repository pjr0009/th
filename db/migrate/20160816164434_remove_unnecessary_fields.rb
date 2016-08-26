class RemoveUnnecessaryFields < ActiveRecord::Migration
  def change
    remove_column :paypal_tokens, :payment_action, :string
    rename_column :paypal_tokens, :express_checkout_url, :paypal_redirect_url
    remove_column :paypal_payments, :authorization_id, :string
    remove_column :paypal_payments, :authorization_date, :string
    remove_column :paypal_payments, :authorization_expires_date, :string
    remove_column :paypal_payments, :authorization_total_cents, :string

    remove_column :paypal_payments, :payment_id
    remove_column :paypal_payments, :payment_date
    remove_column :paypal_payments, :payment_total_cents

    remove_column :paypal_payments, :commission_payment_id
    remove_column :paypal_payments, :commission_payment_date
    remove_column :paypal_payments, :commission_status  
    remove_column :paypal_payments, :commission_pending_reason
    remove_column :paypal_payments, :commission_total_cents
    remove_column :paypal_payments, :commission_fee_total_cents

    rename_column :paypal_payments, :order_id, :ext_transaction_id
    rename_column :paypal_payments, :order_date, :payment_date
    rename_column :paypal_payments, :order_total_cents, :payment_total_cents
    add_column     :paypal_payments, :token, :string
  end
end
