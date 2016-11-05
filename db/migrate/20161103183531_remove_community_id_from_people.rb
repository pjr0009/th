class RemoveCommunityIdFromPeople < ActiveRecord::Migration
  def change
    remove_column :people, :community_id, :integer
    remove_column :emails, :community_id, :integer
    add_column :people, :status, :string, default: "active"
  end
end
