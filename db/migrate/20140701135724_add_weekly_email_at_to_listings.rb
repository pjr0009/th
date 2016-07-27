class AddWeeklyEmailAtToListings < ActiveRecord::Migration
  def change
    add_column :listings, :updates_email_at, :datetime, :after => :created_at, :precision => 0
  end
end
