class CreateLanguagesAndExtendWords < ActiveRecord::Migration
  def self.up
    create_table "languages" do |t|
      t.column "display_name", :string
      t.column "iso_code_2", :string
    end
    
    drop_table "words"
    
    create_table "password_sets" do |t|
      t.column "principal_type", :string
      t.column "principal_id", :string
      t.column "used", :boolean
      t.column "reason", :string # enum
      t.column "created_at", :datetime
    end
    
    remove_column "passwords", "w1"
    remove_column "passwords", "w2"
    remove_column "passwords", "w3"
    remove_column "passwords", "w4"
    remove_column "passwords", "principal_type"
    remove_column "passwords", "principal_id"
    add_column "passwords", "password_set_id", :string
  end

  def self.down
    drop_table "languages"
    drop_table "password_sets"
    
    add_column "passwords", "w1", :integer
    add_column "passwords", "w2", :integer
    add_column "passwords", "w3", :integer
    add_column "passwords", "w4", :integer
    add_column "passwords", "principal_type", :string
    add_column "passwords", "principal_id", :integer
    remove_column "passwords", "password_set_id"
    
    create_table "words", :force => true do |t|
      t.column "text", :string
    end
  end
end
