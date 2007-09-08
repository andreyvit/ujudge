class CreateStatements < ActiveRecord::Migration
  def self.up
    create_table :statements do |t|
      t.column :cookie, :string
      t.column :filename, :string
      t.column :problem_id, :integer
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
  end

  def self.down
    drop_table :statements
  end
end
