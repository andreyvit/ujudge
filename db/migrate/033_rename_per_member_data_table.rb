class RenamePerMemberDataTable < ActiveRecord::Migration
  def self.up
    drop_table :per_member_data
    create_table :per_member_values do |t|
      t.column :member_id, :integer
      t.column :field_id, :integer
      t.column :value, :string
    end
  end

  def self.down
    drop_table :per_member_values
    create_table "per_member_data", :force => true do |t|
      t.column "member_id", :integer
      t.column "field_id",  :integer
      t.column "value",     :string
    end
  end
end
