class AddPointsAndPartialAnswers < ActiveRecord::Migration
  def self.up
    add_column "run_tests", "partial_answer", :string
    add_column "runs", "points", :integer
    add_column "problems", "scoring_method", :string
  end

  def self.down
    remove_column "run_tests", "partial_answer"
    remove_column "runs", "points"
    remove_column "problems", "scoring_method"
  end
end
