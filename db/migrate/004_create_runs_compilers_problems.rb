class CreateRunsCompilersProblems < ActiveRecord::Migration
  FORCE = false
  
  def self.up
    create_table :compilers, :force => FORCE do |t|
      t.column :display_name, :string
      t.column :type, :string
      t.column :extensions, :string
      t.column :executable, :string
    end
    
    create_table :problems, :force => FORCE do |t|
      t.column :contest_id, :integer
      t.column :name, :string
      t.column :display_name, :string
      t.column :input_file, :string
      t.column :output_file, :string
      t.column :check_method, :integer
    end
    
    create_table :runs, :force => FORCE do |t|
      t.column :team_id, :integer
      t.column :problem_id, :integer
      t.column :submitted_at, :datetime
      t.column :file_name, :string
      t.column :compiler_id, :integer
      # 0 submitted, 1 sheduled, 2 testing, 3 tested, 4 reported
      t.column :state, :integer
      t.column :state_assigned_at, :datetime
      # compilation-error, tested
      t.column :outcome, :string
      t.column :test_outcomes, :string
      t.column :details, :text
    end
    # 
    # create_table "run_evaluations" do |t|
    #   t.column "run_id", :integer
    #   t.column "evaluated_at", :datetime
    #   t.column "accepted", :boolean
    #   t.column "penalty_time", :integer
    #   t.column "points", :double
    #   t.column "outcome", :integer
    # end
    
    create_table "run_tests" do |t|
      t.column "run_id", :integer
      t.column "run_at", :datetime
      t.column "test_ord", :integer
      t.column "outcome", :string
    end

  end

  def self.down
    drop_table :compilers
    drop_table :problems
    drop_table :runs
    # drop_table "run_evaluations"
    drop_table "run_tests"
  end
end
