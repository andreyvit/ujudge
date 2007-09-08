class Value < ActiveRecord::Base
  set_table_name "dynamic_values"
  
  belongs_to :field
end
