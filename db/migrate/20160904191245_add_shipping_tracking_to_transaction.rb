class AddShippingTrackingToTransaction < ActiveRecord::Migration
  def change
    add_column :transactions, :shipping_tracking_number, :string
    add_column :transactions, :shipping_provider, :string
  end
end
