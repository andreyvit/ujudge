class AddDisqualifiedToTeams < ActiveRecord::Migration
  def self.up
    add_column :teams, :disqualified, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :teams, :disqualified
  end
end
