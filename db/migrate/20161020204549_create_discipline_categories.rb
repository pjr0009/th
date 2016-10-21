class CreateDisciplineCategories < ActiveRecord::Migration
  def change
    create_table :discipline_categories do |t|
      t.belongs_to :discipline
      t.belongs_to :category

      t.timestamps null: false
    end
  end
end
