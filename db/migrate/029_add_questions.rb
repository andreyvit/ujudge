class AddQuestions < ActiveRecord::Migration
  def self.up
  	create_table :questions do |t|
      t.column :contest_id, :integer, :null => false
      t.column :team_id, :integer, :null => true
      t.column :question, :text, :null => false
	    t.column :answer, :text
	    t.column :visible_for_all_teams, :boolean
	    t.column :visible_for_spectators, :boolean
	    t.column :asked_at, :datetime
	    t.column :answered_at, :datetime
  	end
  end

  def self.down
  	drop_table :questions
  end
end
