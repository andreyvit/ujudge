class TeamsController < ApplicationController
  
  before_filter :set_contest
  before_filter :find_or_initialize_team, :except => ['index', 'list']
  before_filter :setup_team_info, :only => ['new', 'edit', 'create', 'update', 'fill_forms']
  before_filter :set_tabs
  before_filter :set_current_tab
  
  helper :grouped_form
  layout 'control'
  helper :listing
  
  # test
  
  def overview
    find_all_teams
    @forms = Form.find(:all, :select => 'id, title')
    @contest_forms = @contest.forms.find(:all, :select => 'forms.id').collect {|f| f.id}
  end
  
  def update_contest_forms
    @forms = Form.find(:all, :select => 'id, title')
    @contest_forms = @contest.forms.find(:all, :select => 'forms.id').collect {|f| f.id}
    @forms.each do |form|
      if params[:forms].nil? || params[:forms][form.id.to_s].nil?
        if @contest_forms.include?(form.id)
          @contest.forms.delete(form)
        end
      else
        if !@contest_forms.include?(form.id)
          @contest.forms.push(form)
        end
      end
    end
    redirect_to overview_teams_url(@contest)
  end
  
  def index
    @teams = @contest.teams.find(:all, :include => [:university], :order => 'universities.city, universities.name, teams.name')
  end
  
  def new
    render_team_editor(:editing => false)
  end
  
  def edit
    render_team_editor(:editing => true)
  end
  
  def create
    assign_and_save_team_data
    
    @form = @contest.forms.find(:first)
    if @form.nil?
      finish_team_creation
    else
      redirect_to fill_forms_team_url(@contest, @team)
    end
  rescue ActiveRecord::RecordInvalid
    render_team_editor(:editing => false)
  end
  
  def finish_team_creation
    ps = @team.create_passwords!(:registration)
    cookie = SecurityCookie.generate_new(:owner => @team, :usage => 'post_registration')
    cookie.save!
    result = @team.send_password!(:registration)
    
    redirect_to team_url(@contest, @team) + '?cookie=' + cookie.text
  end
  
  def fill_forms
    # FIXME: currently supports max. one form per contest
    @form = @contest.forms.find(:first)
    @fields = @form.fields.find(:all)
    
    @values = PerMemberValue.find(:all, :conditions => {:member_id => @team.members.collect(&:id), 
      :field_id => @fields.collect(&:id)}, :include => [:field])
      
    @members = []
    @team.members.each do |member|
      m = PerMemberInstance.new(member, @fields)
      @fields.each { |f| m[:"#{f.name}"] = nil }
      @values.select { |v| v.member_id == member.id }.each { |v| m[:"#{v.field.name}"] = v.value }
      @members << m
    end

    if params[:members]
      for i, data in params[:members]
        member = @members[i.to_i]
        member.attributes = data unless member.nil?
      end
    end

    if params[:members]
      objects = @members
      if objects.reject {|r| r.valid?}.empty?
        @members.each { |m| m.save! }
        
        return finish_team_creation
      end
    end
  end
  
  def update
    return access_denied unless current_user.is_a?(Team) && current_user.id == @team.id || current_user.allow?(:edit_any_team)
    
    assign_and_save_team_data
    
    flash[:highlight_team] = @team.id
    flash[:message] = "Данные сохранены"

    if current_user.is_a?(User)
      redirect_to edit_team_url(@contest, @team)
    else
      redirect_to edit_team_url(@contest, @team)
    end
  rescue ActiveRecord::RecordInvalid
    render_team_editor(:editing => true)
  end
  
  def destroy
    return access_denied unless current_user.allow?(:delete_team)
    @team.destroy
    respond_to do |wants|
      wants.html {
        flash[:message] = "Команда #{@team.identifying_name} удалена"
        redirect_to select_teams_url(@contest)
      }
      wants.js
    end
  end
  
  def show
    security_violation if params[:cookie].nil?
    
    @team = Team.find(params[:id])
    @password_set = @team.active_password_set
    cookie = SecurityCookie.find_by_owner_and_usage_and_text(@team, 'post_registration', params[:cookie])
    return security_violation if cookie.nil?
    #@form = @contest.form
    #@moredata = @form.render_data(@team)
    render :action => 'post_registration'
  end
  
  def do_select
  end
 
  def select
    return access_denied unless current_user.allow?(:access_team_details)
    
    @listing = Listing.new(current_user, [Team])
    if params[:show]
      @listing.handle_postback(params[:show]) 
    else
      @listing.set_default_visibility
    end
    
    if @params[:export]
      @teams = Team.find(:all, :order => 'id', :conditions => ["contest_id = ?", @contest.id])
      content_type = if request.user_agent =~ /windows/i
          'application/vnd.ms-excel'
        else
          'text/csv'
        end
        
      CSV::Writer.generate(output = "", ";") do |csv|
        csv << @listing.column_names.collect { |v| Iconv::conv('cp1251', 'utf-8', v.to_s) }
        @teams.each do |team|
          csv << @listing.column_values(team).collect { |v| Iconv::conv('cp1251', 'utf-8', v.to_s) }
        end
      end
      
      send_data(output, :type => content_type, :filename => "teams.csv")
      return
    end
    
    @teams = Team.find(:all, :order => 'id DESC', :conditions => ["contest_id = ?", @contest.id])
  end
 
private

  def handle_team_debug_info
    if @team.name == 'debug'
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

  def setup_team_info
    @member_count = @contest.team_members_count
    @members = @team.members
    (@member_count - @members.size).times { @members << Member.new } if @member_count > @members.size
    @university = @team.university || University.new
  end
  
  def render_team_editor(options)
    @universities = University.find(:all, :order => "name")
    @is_editing = options[:editing]
    render :action => 'register'
  end

  def assign_and_save_team_data
    @team.attributes = params[:team]
    @university = @team.university || University.new
    for i, data in params[:members]
      member = @members[i.to_i]
      member.attributes = data unless member.nil?
    end
    
    handle_team_debug_info

    objects = [@team] + @members
    if @team.new_university?
      @university.attributes = params[:university]
      objects << @university
    end
    invalid = objects.reject {|r| r.valid?}
    raise ActiveRecord::RecordInvalid.new(invalid.first) unless invalid.empty?
    if @team.new_university?
      @university.save!
      @team.university = @university
    end
    @team.save!
    @members.each { |m| m.team = @team; m.save! }
    @university.save! if objects.include?(@university)
  end

  def find_all_teams
    @teams = @contest.teams.find(:all)
  end
    
  def find_or_initialize_team
    @team = if params[:id].blank?
      @contest.teams.build
    else
      @contest.teams.find(params[:id], :include => [:members])
    end
  end
  
  def set_current_tab
    @current_tab = :teams
  end
  
end
