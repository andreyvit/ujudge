require File.dirname(__FILE__) + '/../test_helper'

class DynamicModelsTest < Test::Unit::TestCase
  
  # Replace this with your real tests.
  def test_dynamic_model_creation
    team = Team.new
    team.attributes = {:foo => 'bar'}
    team.save!
  end
end
