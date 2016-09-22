class CreatePosts < ActiveRecord::Migration
  def change
    create_table :posts do |t|
      t.string :title
      t.string :partial
      t.string :author
      t.string :slug, unique: true

      t.timestamps null: false
    end
  end
end
