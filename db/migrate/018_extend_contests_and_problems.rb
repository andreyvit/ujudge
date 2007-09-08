class ExtendContestsAndProblems < ActiveRecord::Migration
  def self.up
    add_column :contests, :display_name, :string
    add_column :contests, :created_at, :datetime
    add_column :contests, :updated_at, :datetime
    
    add_column :problems, :letter, :string
    add_column :problems, :available, :boolean, :default => true
    add_column :problems, :created_at, :datetime
    add_column :problems, :updated_at, :datetime
  end

  def self.down
    remove_column :contests, :display_name
    remove_column :contests, :created_at
    remove_column :contests, :updated_at

    remove_column :problems, :letter
    remove_column :problems, :available
    remove_column :problems, :created_at
    remove_column :problems, :updated_at
  end
end
