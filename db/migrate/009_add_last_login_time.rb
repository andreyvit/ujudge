class AddLastLoginTime < ActiveRecord::Migration
  def self.up
    add_column "users", "last_login_at", :datetime
    add_column "teams", "last_login_at", :datetime
    add_column "teams", "password_sent_at", :datetime
  end

  def self.down
    remove_column "users", "last_login_at"
    remove_column "teams", "last_login_at"
    remove_column "teams", "password_sent_at"
  end
end
