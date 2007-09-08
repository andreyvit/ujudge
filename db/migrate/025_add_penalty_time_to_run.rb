class AddPenaltyTimeToRun < ActiveRecord::Migration
  def self.up
    add_column :runs, :penalty_time, :integer
    add_column :contests, :started_at, :datetime
  end

  def self.down
    remove_column :runs, :penalty_time
    remove_column :contests, :started_at
  end
end
