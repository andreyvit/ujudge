class AddPerTeamOverrides < ActiveRecord::Migration
  def self.up
    add_column :teams, :state_override, :integer, :null => true
    add_column :teams, :started_at_override, :datetime, :null => true
  end

  def self.down
    remove_column :teams, :state_override
    remove_column :teams, :started_at_override
  end
end
