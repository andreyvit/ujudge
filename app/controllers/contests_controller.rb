
class ContestsController < ApplicationController
  helper :redbox
  before_filter :set_contest, :except => ['index', 'import', 'manage', 'create_training']
  before_filter :set_tabs
  layout 'control'
      
  def index
    if current_user.is_a?(User)
      redirect_to manage_contests_url
      return
    end
    @contests = Contest.find(:all, :conditions => {:publicly_visible => 1})
  end
      
  def manage
    @contests = Contest.find(:all)
    @server_status = Server.status
  end
  
  def show
    if current_user.is_a?(Team) && current_user.contest_id == @contest.id
      redirect_to team_participation_url(@contest, current_user)
    elsif current_user.allow?(:edit_contest)
      redirect_to edit_contest_url(@contest) 
    else
      # show
      @messages = @contest.messages.find(:all, :order => 'messages.created_at DESC') 
    end
  end
  
  def edit
  end
  
  def update
    @contest.attributes = params[:contest]
    @contest.state = params[:contest][:state] unless params[:contest][:state].nil?
    @contest.save!
    flash[:notice] = "Изменения сохранены"
    redirect_to :back
  end
  
  def create_training
    @contest = Contest.create(:rating_visibility => 0)
    redirect_to edit_contest_url(@contest)
  end
  
  def import
    xml_data = @params[:file].read
    data = Hash.from_xml(xml_data)['hash']
    new_contest, new_universities, new_teams, new_members, new_password_sets, new_passwords = data['contest'], data['universities']['university'], data['teams']['team'], data['members']['member'], data['password_sets']['password_set'], data['passwords']['password']
    
    log = ''
    contest = Contest.create!(new_contest.merge({'id' => nil}))
    log << "contest #{contest.id}\n"
    new_teams.each do |new_team|
      new_university = new_universities.find { |u| u['id'] == new_team['university_id'] }
      unless new_university.nil?
        university = University.find_by_name(new_university['name'])
        if university.nil?
          university = University.create!(new_university.merge({'id' => nil}))
        end
      end
      
      team = Team.create!(new_team.merge({'id' => nil, 'contest_id' => contest.id,
          'university_id' => university.id}))
      log << "team #{team.id}\n"
      
      new_members.each do |new_member|
        next unless new_member['team_id'] == new_team['id']
        member = Member.create!(new_member.merge({'id' => nil, 'team_id' => team.id}))
        log << "  member #{member.id}\n"
      end
      
      new_password_sets.each do |new_password_set|
        next unless new_password_set['principal_id'].to_i == new_team['id']
        password_set = PasswordSet.create!(new_password_set.merge({'id' => nil, 'principal_id' => team.id}))
        log << "  password set #{password_set.id}\n"
      
        new_passwords.each do |new_password|
          next unless new_password['password_set_id'].to_i == new_password_set['id']
          password = Password.create!(new_password.merge({'id' => nil, 'password_set_id' => password_set.id}))
          log << "    password #{password.id}\n"
        end
      end
    end
    #send_data(log, :filename => 'export', :type => 'text/plain', :disposition => 'inline')
    redirect_to contest_url(contest.id)
  end
  
  def export
    @teams = @contest.teams.find(:all, :include => [:members, :university])
    @members = @teams.collect { |t| t.members }.flatten
    @universities = @teams.collect { |t| t.university }
    @password_sets = PasswordSet.find_all_by_principal_type_and_principal_id('Team', @teams)
    @passwords = Password.find_all_by_password_set_id(@password_sets)
    data = {:contest => @contest, :teams => @teams, :members => @members, :universities => @universities, :password_sets => @password_sets, :passwords => @passwords}.to_xml
    send_data(data, :filename => "contest_#{@contest.id}_#{Time.now.strftime('%Y%m%d_%H%M')}.xml", :type => 'text/xml', :disposition => 'attachment')
  end
  
protected
  
	def set_contest
    @contest = Contest.find(params[:id])
	end

end



