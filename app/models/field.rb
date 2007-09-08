class Field < ActiveRecord::Base
  set_table_name "dynamic_fields"
  
  belongs_to :contest
  belongs_to :entity
  belongs_to :type
  belongs_to :language
end
