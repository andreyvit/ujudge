class AddConstestPolicies < ActiveRecord::Migration
  def self.up
    add_column :contests, :registration_open, :integer,    :default => 0, :null => false
    add_column :contests, :statements_available, :integer, :default => 0, :null => false
    add_column :contests, :publicly_visible, :integer, :default => 0, :null => false
  end

  def self.down
    remove_column :contests, :registration_open
    remove_column :contests, :statements_available
    remove_column :contests, :publicly_visible
  end
end
