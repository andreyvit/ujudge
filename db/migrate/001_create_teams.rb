class CreateTeams < ActiveRecord::Migration
  def self.up
    create_table :teams do |t|
      t.column :name, :string, :null => false
      t.column :email, :string
      t.column :coach_names, :string
      t.column :coach_email, :string
    end  
    
    create_table :members do |t|
      t.column :team_id, :integer, :null => false
      t.column :first_name, :string
      t.column :last_name, :string
      t.column :middle_name, :string
      t.column :email, :string
      t.column :year_id, :integer
    end
  end

  def self.down
    drop_table :teams
    drop_table :members
  end
end
