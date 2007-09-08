class CreateSamsungForms < ActiveRecord::Migration
  def self.up
    create_table :samsung_forms do |t|
      t.column :member_id, :integer
      
      t.column :fname, :string
      t.column :pname, :string
      t.column :sname, :string
      t.column :gender, :string
      t.column :birth_date, :date
      t.column :birth_place, :string
      t.column :marital_status, :string
      t.column :children, :string
      t.column :mailing_address, :string
      t.column :home_phone, :string
      t.column :work_phone, :string
      t.column :mobile_phone, :string
      t.column :email, :string

      t.column :edu_spec, :string
      t.column :edu_period, :string
      t.column :edu_university, :string
      t.column :edu_courses, :string
      t.column :edu_awards, :string
    end
  end

  def self.down
    drop_table :samsung_forms
  end
end
