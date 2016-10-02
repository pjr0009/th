class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.string :model, null: false
      t.references :brand, index: true
      t.timestamps null: false
    end
    add_reference :listings, :product, index: true 
    add_attachment :products, :image
  end
end
