class SamsungForm < ActiveRecord::Base
  belongs_to :member
  
  validates_presence_of :fname, :message => :required_field_n.s
  validates_presence_of :pname, :message => :required_field_n.s
  validates_presence_of :sname, :message => :required_field_n.s
  validates_presence_of :gender, :message => :required_field_n.s
  validates_presence_of :birth_date, :message => :required_field_n.s
  validates_presence_of :birth_place, :message => :required_field_n.s
  validates_presence_of :marital_status, :message => :required_field_n.s
  validates_presence_of :children, :message => :required_field_n.s
  validates_presence_of :mailing_address, :message => :required_field_n.s
  validates_presence_of :edu_spec, :message => :required_field_n.s
  validates_presence_of :edu_period, :message => :required_field_n.s
  validates_presence_of :edu_university, :message => :required_field_n.s

end
