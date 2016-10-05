class CreateDisciplines < ActiveRecord::Migration
  def change
    create_table :disciplines do |t|
      t.text :summary
      t.string :name
      t.timestamps null: false
    end
    add_reference :listings, :discipiline, index: true
    add_attachment :disciplines, :illustration
  end
end
