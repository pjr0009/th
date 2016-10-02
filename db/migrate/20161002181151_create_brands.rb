class CreateBrands < ActiveRecord::Migration
  def change
    create_table :brands do |t|
      t.timestamps null: false
      t.string :summary

    end

    add_attachment :brands, :logo
    add_reference :listings, :brand, index: true
    create_table :disciplines_brands, id: false do |t|
      t.belongs_to :discipline, index: true
      t.belongs_to :brand, index: true
    end
  end
  
end
