class AddProblemTestDependencies < ActiveRecord::Migration
  def self.up
    add_column :problems, :test_dependencies, :text
  end

  def self.down
    remove_column :problems, :test_dependencies
  end
end
