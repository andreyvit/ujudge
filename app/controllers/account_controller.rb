class AccountController < ApplicationController

  def login
    pwd = Password.authenticate(params['password'])
    if pwd.nil?
      @failure = true
      respond_to do |wants|
        # wants.js    { flash.now[:login_failure] = true; render :action => 'login_failure.rjs' }
        wants.html  { flash[:login_failure] = true; redirect_to :back }
      end
    else
      session['user'] = @user = pwd.password_set.principal
      @target = :back
      if @user.is_a?(Team)
        @target = team_participation_url(@user.contest, @user)
      end
      @user.last_login_at = Time.now
      @user.save!
      respond_to do |wants|
        # wants.js    { render_reload_js }
        wants.html  { redirect_to @target }
      end
    end
  end
  
  def logout
    session['user'] = AnonymousUser.new
    respond_to do |wants|
      # wants.js    { render_reload_js }
      wants.html  { redirect_to home_url }
    end
  end
    
end
