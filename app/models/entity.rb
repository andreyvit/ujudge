class Entity < ActiveRecord::Base
  has_many :fields
  
  def all_fields
    self.fields
  end
end
