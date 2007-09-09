class Field < ActiveRecord::Base
  belongs_to :form
  
  def choices_as_array
    self.choices.split(",").collect { |c| c.strip }.collect { |s| [s, s] }
  end
end
