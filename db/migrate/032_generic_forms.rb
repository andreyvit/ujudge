class GenericForms < ActiveRecord::Migration
  def self.up
    drop_table :forms
    
    create_table :forms do |t|
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
      
      t.column :title, :string
      t.column :comment, :text
    end
    
    create_table :contests_forms do |t|
      t.column :contest_id, :integer
      t.column :form_id, :integer
    end
    
    create_table :fields do |t|
      t.column :form_id, :integer
      t.column :name, :string
      t.column :data_type, :string
      t.column :choices, :text
      t.column :required, :boolean
      
      t.column :label, :string
      t.column :comment, :text
    end
    
    create_table :per_member_data do |t|
      t.column :member_id, :integer
      t.column :field_id, :integer
      t.column :value, :string
    end
  end

  def self.down
    drop_table :forms
    drop_table :contests_forms
    drop_table :per_member_form_data
    drop_table :fields

    create_table :forms, :force => true do |t|
      t.column "type",       :string,  :default => "", :null => false
      t.column "contest_id", :integer,                 :null => false
    end
  end
end
