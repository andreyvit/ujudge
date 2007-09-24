class AddContestRatingVisibility < ActiveRecord::Migration
  def self.up
    add_column :contests, :rating_visibility, :integer, :null => false
    add_column :contests, :rating_comment, :string
    execute "update contests set rating_visibility = 1"
  end

  def self.down
    remove_column :contests, :rating_visibility
    remove_column :contests, :rating_comment
  end
end
