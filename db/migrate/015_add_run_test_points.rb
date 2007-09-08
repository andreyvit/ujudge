class AddRunTestPoints < ActiveRecord::Migration
  def self.up
    add_column "run_tests", "points", :string
  end

  def self.down
    remove_column "run_tests", "points"
  end
end
