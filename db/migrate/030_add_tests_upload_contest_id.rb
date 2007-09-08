class AddTestsUploadContestId < ActiveRecord::Migration
  def self.up
    add_column :tests_uploads, :contest_id, :integer, :null => false
  end

  def self.down
    remove_column :tests_uploads, :contest_id
  end
end
