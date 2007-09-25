class AddTestListFieldToRun < ActiveRecord::Migration
  def self.up
    add_column :runs, :tests_filter, :text, :null => true
  end

  def self.down
    remove_column :runs, :tests_filter
  end
end
