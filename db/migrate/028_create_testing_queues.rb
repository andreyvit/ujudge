class CreateTestingQueues < ActiveRecord::Migration
  def self.up
    create_table :testing_queues do |t|
    end
  end

  def self.down
    drop_table :testing_queues
  end
end
