class CreateNewsPosts < ActiveRecord::Migration
  def change
    create_table :news_posts do |t|
      t.string :title
      t.string :partial
      t.string :person_id
      t.string :slug, unique: true
      t.string :summary
      t.timestamps null: false
    end
    add_attachment :news_posts, :image
    add_column :people, :website, :string
  end
end
