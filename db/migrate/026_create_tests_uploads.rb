class CreateTestsUploads < ActiveRecord::Migration
  def self.up
    create_table :tests_uploads do |t|
      t.column :problem_id, :integer
      t.column :filename, :string
      t.column :original_filename, :string
      t.column :state, :integer
      t.column :message, :text
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
  end

  def self.down
    drop_table :tests_uploads
  end
end
