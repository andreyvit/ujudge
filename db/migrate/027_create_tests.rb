class CreateTests < ActiveRecord::Migration
  def self.up
    create_table :tests do |t|
      t.column :problem_id, :integer
      t.column :position, :integer
      t.column :input_file, :string
      t.column :answer_file, :string
    end
  end

  def self.down
    drop_table :tests
  end
end
