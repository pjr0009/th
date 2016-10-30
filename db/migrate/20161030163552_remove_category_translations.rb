class RemoveCategoryTranslations < ActiveRecord::Migration
  def change
    remove_column :categories, :slug
    remove_column :categories, :name
    add_column :categories, :name, :string, :null => false
    add_column :categories, :slug, :string, :unique => true
    Discipline.destroy_all
    Discipline.create!(:name => "Western")
    Discipline.create!(:name => "English")
    Discipline.find_each do |discipline|
      discipline.categories << Category.all
    end
    Category.find_each do |category|
        category.name = category.translations.first.name
        category.save!
    end
  end
end
