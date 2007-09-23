class AddQuestionProblemId < ActiveRecord::Migration
  def self.up
    add_column :questions, :problem_id, :integer, :null => true
  end

  def self.down
    remove_column :questions, :problem_id
  end
end
