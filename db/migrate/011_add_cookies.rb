class AddCookies < ActiveRecord::Migration
  def self.up
    create_table "cookies" do |t|
      t.column "owner_type", :string, :null => false
      t.column "owner_id", :integer, :null => false
      t.column "text", :string, :null => false
      t.column "created_at", :datetime, :null => false
      t.column "usage", :string, :null => false
      t.column "expires_at", :datetime
    end
  end

  def self.down
    drop_table "cookies"
  end
end
