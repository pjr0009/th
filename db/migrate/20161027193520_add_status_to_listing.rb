class AddStatusToListing < ActiveRecord::Migration
  def change
    add_column :listings, :status, :string, :default => "start"
  end
end
