class AddRatings < ActiveRecord::Migration
  def self.up
    create_table "ratings" do |t|
      t.column "rating_definition_id", :integer, :null => false
      t.column "item_id", :integer
      t.column "value", :text
      t.column "created_at", :datetime, :null => false
      t.column "updated_at", :datetime, :null => false
    end
    
    create_table "rating_definitions" do |t|
      t.column "contest_id", :integer, :null => false
      t.column "scope_type", :string, :null => false
      t.column "parent_scope_id", :integer, :null => true
      t.column "options", :text, :null => false
      t.column "created_at", :datetime, :null => false
      t.column "updated_at", :datetime, :null => false
    end
  end
  
  def self.down
    drop_table "ratings"
    drop_table "rating_definitions"
  end
end
