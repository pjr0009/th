class AddAdditionalFieldsToPosts < ActiveRecord::Migration
  def change
    add_column :posts, :feature_image_large, :string, :null => false
    add_column :posts, :external_attribution_url, :string
    add_column :posts, :summary, :text, :null => false
    
  end
end
