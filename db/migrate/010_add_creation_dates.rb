class AddCreationDates < ActiveRecord::Migration
  def self.up
    add_column "members", "created_at", :datetime
    add_column "teams", "created_at", :datetime
    add_column "samsung_forms", "created_at", :datetime
    add_column "universities", "created_at", :datetime
    add_column "users", "created_at", :datetime
  end

  def self.down
    remove_column "members", "created_at"
    remove_column "teams", "created_at"
    remove_column "samsung_forms", "created_at"
    remove_column "universities", "created_at"
    remove_column "users", "created_at"
    remove_column "teams", "cookie"
  end
end
