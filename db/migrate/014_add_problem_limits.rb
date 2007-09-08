class AddProblemLimits < ActiveRecord::Migration
  def self.up
    add_column "problems", "time_limit", :integer
    add_column "problems", "memory_limit", :string
  end

  def self.down
    remove_column "problems", "time_limit"
    remove_column "problems", "memory_limit"
  end
end
