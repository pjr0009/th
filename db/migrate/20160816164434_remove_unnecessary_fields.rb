class RemoveUnnecessaryFields < ActiveRecord::Migration
  def change
    remove_column :paypal_tokens, :payment_action, :string
    # remove_column :paypal_tokens, :payment_action, :string
    # rename_column :paypal_tokens, :express_checkout_url, :redirect_url
    
  end
end
