class CreateSales < ActiveRecord::Migration
  def change
    create_table :sales do |t|
      t.references :brand, :index => true
      t.references :product, :index => true
      t.references :transactions, :index => true
      t.string :external_source
      t.string :external_location
      t.timestamps null: false
    end
    add_column :listings, :original_price_cents, :integer
    add_money :sales, :asking_price, amount: { default: 0 }
    add_money :sales, :sold_price, amount: { default: 0 }
    add_index :sales, [:brand_id, :product_id, :external_location], unique: true
  end
end
