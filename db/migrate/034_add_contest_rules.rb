class AddContestRules < ActiveRecord::Migration
  def self.up
    add_column :contests, :rules, :string
    execute "update contests set rules='acm'"
  end

  def self.down
    remove_column :contests, :rules
  end
end
