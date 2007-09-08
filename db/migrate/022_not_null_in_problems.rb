class NotNullInProblems < ActiveRecord::Migration
  def self.up
    execute "update problems set check_method = 2 where check_method is null;"
    change_column :problems, :check_method, :integer, :default => 2, :null => false
    change_column :problems, :scoring_method, :string, :default => "", :null => false
  end

  def self.down
  end
end
