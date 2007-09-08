class AddForms < ActiveRecord::Migration
  def self.up
    create_table "forms" do |t|
      t.column "type", :string, :null => false
      t.column "contest_id", :integer, :null => false
    end
    add_column "teams", "form_data", :text
    create_table :imagine_cup_recs do |t|
      t.column "team_id", :integer, :null => false
      t.column "created_at", :datetime
    end
  end

  def self.down
    drop_table "forms"
    remove_column "teams", "form_data"
    drop_table :imagine_cup_recs
  end
end
