require File.dirname(__FILE__) + '/../test_helper'

class TeamTest < Test::Unit::TestCase
  fixtures :teams
  
  GOOD_TEAM = {:name => "nsu3", :email => "nsu3@gorodok.net", :password => "piapugha",
    :coach_names => "NSU Training", :coach_email => "tanch@iis.nsk.su"}
    
  BAD_TEAM = {:name => "", :email => "", :password => "", :coach_names => "", :coach_email => ""}

  # Replace this with your real tests.
  def test_team_registration
    t = Team.new
    assert !t.valid?
    
    for f in BAD_TEAM.keys
      t.attributes = GOOD_TEAM.dup.update(f => BAD_TEAM[f])
      assert !t.valid?
    end
    
    t.attributes = GOOD_TEAM
    assert t.valid?
    assert t.save
  end
end
