class RenameListingDiscipline < ActiveRecord::Migration
  def change
    rename_column :listings, :discipiline_id, :discipline_id
    add_column :disciplines, :slug, :string, :unique => true
  end
end
