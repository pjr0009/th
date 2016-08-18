class RemoveUnnecessaryFields < ActiveRecord::Migration
  def change
    remove_column :paypal_tokens, :payment_action, :string
    rename_column :paypal_tokens, :express_checkout_url, :paypal_redirect_url
    remove_column :paypal_payments, :authorization_id, :string
    remove_column :paypal_payments, :authorization_date, :string
    remove_column :paypal_payments, :authorization_expires_date, :string
    remove_column :paypal_payments, :authorization_total_cents, :string

    # remove_column :paypal_tokens, :payment_action, :string
    
  end
end
