require File.dirname(__FILE__) + '/../test_helper'
require 'teams_controller'

# Re-raise errors caught by the controller.
class TeamsController; def rescue_action(e) raise e end; end

class TeamsControllerTest < Test::Unit::TestCase
  
  fixtures :contests, :universities, :teams, :members, :users
  
  FIRST_NAMES = ["Иван", "Петя", "Вася"]
  LAST_NAMES  = ["Петров", "Васильев", "Иванов"]
  MIDDLE_NAMES = ["Первый", "Второй", "Третий"]
  
  def correct_team()
    result = {}
    result[:team] = {
      :name => 'Novosibirsk SU #1',
      :email => 'me@me.com',
      :coach_names => 'Преподаватели НГУ',
      :coach_email => 'tanch@iis.nsk.su',
      :university_id => 1
    }
    result[:members] = {}
    3.times do |i|
      result[:members][i] = {
        :first_name => FIRST_NAMES[i],
        :last_name => LAST_NAMES[i],
        :middle_name => MIDDLE_NAMES[i],
        :email => '',
        :year_id => 4,
        :faculty => 'FIT'
      }
    end
    return result
  end
  
  def setup
    @controller = TeamsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @contest = Contest.find_by_short_name('pottosin')
    @sess = ActionController::TestSession.new
  end

  def test_failed_register
    info = correct_team
    info[:team][:name] = ''
    info[:contest_name] = @contest.short_name
    post :register, info
    assert_response :success
    assert_not_nil @response.flash
    assert_template 'register'
    @team = Team.find_by_contest_id_and_name(@contest.id, info[:team][:name])
    assert_nil @team
  end

  def test_bad_contest
    info = correct_team
    info[:team][:name] = ''
    info[:contest_name] = 'abrakadabra'
    assert_raise ActiveRecord::RecordNotFound do post :register, info end
    # assert_response :failure
  end

  def test_register
    info = correct_team
    info[:team][:name] = 'nsufifty'
    info[:contest_name] = @contest.short_name
    post :register, info
    assert_redirected_to :action => 'post_registration'
    @team = Team.find_by_contest_id_and_name(@contest.id, info[:team][:name])
    assert_not_nil @team
  end
  
  def test_unauthenticated_edit
    do_edit_team
    assert_response 403
  end
  
  def test_unauthorized_edit
    @sess[:user] = Team.find_by_name('astu_a')
    do_edit_team
    assert_response 403
  end
  
  def test_jury_edit
    @sess[:user] = User.find(1)
    do_edit_team
    assert_successful_edit
  end
  
  def test_authorized_edit
    @sess[:user] = Team.find_by_name('nsu1')
    @sess[:user] = 123
    do_edit_team
    assert_successful_edit
  end
  
  def do_edit_team
    team = Team.find_by_name('nsu1')
    corteam = correct_team
    @info = load_team_info(team, corteam)
    
    @info[:contest_name] = @contest.short_name
    @info[:id] = team.id
    @info[:team][:name] = 'nsu2'
    
    post :register, @info, @sess
  end
  
  def assert_successful_edit
    assert_redirected_to :action => 'index'
    @team = Team.find_by_contest_id_and_name(@contest.id, @info[:team][:name])
    assert_not_nil @team
    assert_equal @team.name, @info[:team][:name]
  end
  
  def load_team_info(team, corteam)
    info = {:team => {}, :members => {}}
    team.attributes.each { |k,v|
      k = :"#{k}"
      info[:team][k] = v if corteam[:team][k]
    }
    team.members.each_with_index do |member, i|
      info[:members][i] = {}
      member.attributes.each { |k,v|
         k = :"#{k}"
         info[:members][i][k] = v if corteam[:members][0][k]
      }
    end
    return info
  end
  
  def foo
    @team.name = ''
    @team.email = 'me@me.com'
    @team.coach_names = "Преподаватели НГУ"
    @team.coach_email = "tanch@iis.nsk.su"
    @team.university_id = 1
    @member_count.times do |i|
      @members[i].first_name = "Участник"
      @members[i].last_name = (i+1).to_russian_ordinal(:i)
      @members[i].middle_name = "Некоторый"
      @members[i].email = "andreyvit+test#{i+1}@gmail.com"
      @members[i].year_id = 4
    end
  end
end
