require_dependency 'dynamic_fields'

class Member < ActiveRecord::Base
  include DynamicFields::Model
  
  belongs_to :team
  
  before_validation :foo
  
  validates_presence_of :first_name, :message => :required_field_n.s
  validates_length_of :first_name, :minimum => 2

  validates_presence_of :last_name, :message => :required_field_f.s
  validates_length_of :last_name, :minimum => 2

  validates_presence_of :middle_name, :message => :required_field_n.s
  validates_length_of :middle_name, :minimum => 2

  validates_email :email, :allow_nil => true, :message => "Нужно указать правильный адрес или оставить поле пустым"

#  validates_presence_of :faculty, :message => :required_field_m.s
#  validates_length_of :faculty, :minimum => 4
  
  validates_selected_index :year_id
  
  
  def foo
    self.email = nil if self.email.is_a?(String) && self.email.strip.length == 0
  end
end
