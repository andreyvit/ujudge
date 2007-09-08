class IntroduceSubmittions < ActiveRecord::Migration
  def self.up
    create_table :submittions do |t|
      t.column :problem_id,   :integer
      t.column :team_id,      :integer
      t.column :compiler_id,  :integer
      t.column :submitted_at, :datetime
      t.column :file_name,    :string
      t.column :state,        :integer
      t.column :state_assigned_at, :datetime
      t.column :created_at,   :datetime
    end
    
    add_column :runs, :submittion_id, :integer
  end

  def self.down
    drop_table :submittions
    remove_column :runs, :submittion_id, :integer
  end
end
