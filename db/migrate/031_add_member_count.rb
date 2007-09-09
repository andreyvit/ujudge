class AddMemberCount < ActiveRecord::Migration
  def self.up
    add_column :contests, :team_members_count, :integer
    execute "UPDATE contests SET team_members_count = 3"
  end

  def self.down
    remove_column :contests, :team_members_count
  end
end
