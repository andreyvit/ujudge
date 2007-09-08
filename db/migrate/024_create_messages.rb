class CreateMessages < ActiveRecord::Migration
  def self.up
    create_table :messages do |t|
      t.column :text, :text, :null => false
      t.column :contest_id, :integer, :null => false
      t.column :created_at, :datetime
      t.column :updates_at, :datetime
    end
  end

  def self.down
    drop_table :messages
  end
end
