class AddContestStateAndWelcomeMessage < ActiveRecord::Migration
  def self.up
    add_column :contests, :state, :integer, :default => 0, :null => false
    add_column :contests, :ending_at, :datetime
    add_column :contests, :welcome_message, :text
  end

  def self.down
    remove_column :contests, :state
    remove_column :contests, :ending_at
    remove_column :contests, :welcome_message
  end
end
