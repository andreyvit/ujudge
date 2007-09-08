
class Submittion < ActiveRecord::Base
  
  belongs_to :team
  belongs_to :problem
  belongs_to :compiler
  
  has_many :runs
  
  attr_accessor :text
  
  def state=(value) 
    write_attribute(:state, value)
    write_attribute(:state_assigned_at, Time.new)
  end
  
end
