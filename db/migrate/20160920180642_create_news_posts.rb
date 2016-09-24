class CreateNewsPosts < ActiveRecord::Migration
  def change
    create_table :news_posts do |t|
      t.string :title
      t.string :partial
      t.references :person
      t.string :slug, unique: true
      t.string :summary
      t.timestamps null: false
    end
    add_attachment :news_posts, :image

  end
end
