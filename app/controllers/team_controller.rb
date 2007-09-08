class TeamsController < ApplicationController
  include ContestAcceptor
  helper :grouped_form
  helper :listing
  
  before_filter :login_required, :except => [:index, :register, :samsung, :post_registration]
  
  def index
    accept_contest
    
    @teams = Team.find(:all, :order => 'universities.name, teams.name', :conditions => ["contest_id = ?", @contest.id],
      :include => [:university])
  end
  
  def select
    return access_denied unless current_user.allow?(:access_team_details)
    accept_contest
    
    @listing = Listing.new(current_user, [Team])
    if request.post?
      @listing.handle_postback(@params[:show]) 
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
  
  def reset_password
    return access_denied unless current_user.allow?(:reset_password)
    accept_contest
    @team = Team.find(@params[:team_id])
    ps = @team.create_passwords!(:change)
    
    Mails.deliver_team_password_notification(@team, ps, :change)
    begin
      Mails.deliver_team_password_notification(team, ps, :reset)
    rescue Exception => e
      RAILS_DEFAULT_LOGGER.warn "Error sending message to #{@team.email}: #{e}"
      flash[:message] = "Ошибка отправки пароля по адресу #{@team.email}! #{e}"
    else
      flash[:message] = "Пароль для команды #{@team.name} успешно создан и выслан по адресу #{@team.email}"
    end
    redirect_to :back
  end
  
  # def after
  #   return access_denied unless current_user.allow?(:reset_password)
  #   accept_contest
  #   @team = Team.find(@params[:team_id])
  #   ps = @team.create_passwords!(:change)
  #   
  #   Mails.deliver_team_password_notification(@team, ps, :change)
  #   begin
  #     Mails.deliver_team_password_notification(team, ps, :reset)
  #   rescue Exception => e
  #     RAILS_DEFAULT_LOGGER.warn "Error sending message to #{@team.email}: #{e}"
  #     flash[:message] = "Ошибка отправки пароля по адресу #{@team.email}! #{e}"
  #   else
  #     flash[:message] = "Пароль для команды #{@team.name} успешно создан и выслан по адресу #{@team.email}"
  #   end
  #   redirect_to :back
  # end
  
  def reset_all_passwords
    return access_denied unless current_user.allow?(:reset_all_passwords)
    accept_contest
    @teams = @contest.teams
    @errors = []
    @ok = []
    @teams.each do |team|
      next unless team.password_sent_at.nil? || params[:force]
      ps = team.create_passwords!(:reset)
      begin
        Mails.deliver_team_password_notification(team, ps, :reset)
      rescue Exception => e
        RAILS_DEFAULT_LOGGER.warn "Error sending message to #{team.email}: #{e}"
        @errors << team
      else
        RAILS_DEFAULT_LOGGER.info "Password message sent to #{team.email}"
        @ok << team
        team.password_sent_at = Time.now
        team.save!
      end
    end
    flash[:message] = "Пароли для #{@ok.size} команд успешно созданы и высланы им по электронной почте, еще возникло #{@errors.size} ошибок с командами #{@errors.collect {|t| t.name}.join(', ')}."
    redirect_to :action => 'select'
  end
  
  def admin_login
    return access_denied unless current_user.allow?(:admin_login_team)
    accept_contest
    @team = Team.find(@params[:team_id])
    @session['user'] = @team
    redirect_to :controller => 'contest', :action => 'index'
  end
  
  def resend
    return access_denied unless current_user.allow?(:resend_team_auth)
    @team = Team.find(@params[:id])
    Mails.deliver_team_registration_confirmation(@team)
    render_text "Done at " + Time.now.strftime("%s")
  end
  
  def register
    return security_violation unless params[:id].nil?
    register_or_edit
  end
  
  def edit
    redirect_to :action => 'index' if params[:id].nil?
    register_or_edit
  end

  def register_or_edit
    accept_contest
    @form = @contest.form

    @member_count = 1 # currently a constant
    @universities = University.find(:all, :order => "name")
    
    if params[:id]
      @is_editing, @team = true, Team.find(params[:id], :include => [:members])
      return access_denied unless current_user.is_a?(Team) && current_user.id == @team.id || current_user.allow?(:edit_any_team)
    else
      @is_editing, @team = false, Team.new
    end
    @team.contest ||= @contest
    @team.attributes = params[:team] if request.post?
    
    @university = @team.university || University.new

    @members = @team.members
    (@member_count - @members.size).times { @members << Member.new } if @member_count > @members.size
    if request.post?
      for i, data in params[:members]
        member = @members[i.to_i]
        member.attributes = data unless member.nil?
      end
    end
        
    if request.post?
      objects = [@team] + @members
      if @team.new_university?
        @university.attributes = params[:university] if request.post?
        objects << @university
      end
      if objects.reject {|r| r.valid?}.empty?
        if @team.new_university?
          @university.save!
          @team.university = @university
        end
        @team.save!
        @form.create_data!(@team)
        @team.save!
        @members.each { |m| m.team = @team; m.save! }
        
        if !@is_editing && @form.samsung?(@team)
          redirect_to :action => 'samsung', :team_id => @team.id
          return
        end

        unless @is_editing
          return finish_team_registration
        end
                
        # Mails.deliver_team_registration_confirmation(@team)
        
        flash[:highlight_team] = @team.id
        if @is_editing
          flash[:message] = "Данные о команде успешно сохранены"
        else
          # flash[:message] = "Ваша командаe зарегистрирована"
        end
        if current_user.is_a?(User)
          redirect_to :action => 'select'
        else
          redirect_to :action => 'index'
        end
        return
      end
    end
    
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
    
    render :action => 'register'
  end
  private :register_or_edit
  
  def delete
    return access_denied unless current_user.allow?(:delete_team)
    accept_contest
    @team = Team.find(params[:team_id])
    @team.destroy
    redirect_to :action => 'select', :contest_name => @contest.short_name
  end
    
  def samsung
    accept_contest
    @form = contest.form
    @team = Team.find(params[:team_id])

    @member_count = @team
    @members = []
    @team.members.each { |member|
      id = member.id
      m = SamsungForm.find_by_member_id(id)
      next unless m.nil?
      @members << SamsungForm.new(:member => member)
    }
    
    if @members.empty?
        flash[:highlight_team] = @team.id
        redirect_to :action => 'index'
        return
    end
    
    if request.post?
      for i, data in params[:members]
        member = @members[i.to_i]
        member.attributes = data unless member.nil?
      end
    end
        
    if request.post?
      objects = @members
      if objects.reject {|r| r.valid?}.empty?
        @members.each { |m| m.save! }
        
        return finish_team_registration
      end
    end
  end
  
  def finish_team_registration
    ps = @team.create_passwords!(:registration)
    cookie = SecurityCookie.generate_new(:owner => @team, :usage => 'post_registration')
    cookie.save!
    
    result = @team.send_password!(:registration)
    
    redirect_to :action => 'post_registration', :id => @team.id, :cookie => cookie.text
  end
  
  def post_registration
    security_violation if params[:cookie].nil?
    
    accept_contest
    @team = Team.find(params[:id])
    @password_set = @team.active_password_set
    cookie = SecurityCookie.find_by_owner_and_usage_and_text(@team, 'post_registration', params[:cookie])
    security_violation if cookie.nil?
    @form = @contest.form
    @moredata = @form.render_data(@team)
  end
end
