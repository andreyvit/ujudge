class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.column :first_name, :string
      t.column :last_name, :string
      t.column :middle_name, :string
      t.column :position, :string
      t.column :email, :string
      t.column :password_id, :integer
    end
    
    create_table :contests do |t|
      t.column :short_name, :string
      t.column :name, :string
      t.column :reg_message, :text
    end
    
    create_table :words do |t|
      t.column :text, :string
    end

    create_table :passwords do |t|
      t.column :text, :string
      t.column :principal_type, :string
      t.column :principal_id, :integer
      t.column :w1, :integer
      t.column :w2, :integer
      t.column :w3, :integer
      t.column :w4, :integer
    end

    create_table :universities do |t|
      t.column :name, :string
      t.column :city, :string
      t.column :address, :string
      t.column :zip, :string
      t.column :person_for_invitation, :string
    end
    
    add_column :teams, :university_id, :integer
    add_column :teams, :contest_id, :integer
    add_column :members, :faculty, :string
  end

  def self.down
    drop_table :users
    drop_table :contests
    drop_table :words
    drop_table :passwords
    drop_table :universities

    remove_column :teams, :university_id
    remove_column :teams, :contest_id
    remove_column :members, :faculty
  end
end
