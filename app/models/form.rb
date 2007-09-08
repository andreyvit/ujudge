
class FormField
  attr_accessor :name
  attr_accessor :type
  attr_accessor :required
  
  def initialize(name, type)
    @name = name
    @type = type
  end
  
end

class Form < ActiveRecord::Base
  
  def valid?(record)
    true
  end
  
  def action
    "register"
  end
  
  def samsung?(team)
    true
  end
  
  def create_data!(team)
    nil
  end
  
  def render_data(team)
    nil
  end
  
end
