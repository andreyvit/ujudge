require File.dirname(__FILE__) + '/../test_helper'

class DynamicFormsTest < Test::Unit::TestCase
  
  def team_form(form)
    class << form
      def fields
        
      end
    end
  end

  def test_dynamic_form
    form = team_form(Form.new)
    
    team = Team.new
    class << team
      def name; "Vanya"; end
    end
    
    team.valid?
    
    x = team.read_dynamic_attr(:team_name)
    team.write_dynamic_attr(:team_name, 'Something')
  end
end
