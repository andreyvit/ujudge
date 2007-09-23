class JuryController < ApplicationController
  
  before_filter :login_required
  before_filter :set_new_user
  
  # ajax_scaffold :user,        :rows_per_page => 10, :suffix => true
  # ajax_scaffold :contest,     :rows_per_page => 10, :suffix => true
  # ajax_scaffold :member,      :rows_per_page => 20, :suffix => true
  
  def index
    return access_denied unless current_user.allow?(:jury)
  end
  
  def invite
    return access_denied unless current_user.allow?(:jury)
    return access_denied unless current_user.allow?(:invite_jury)
    
    @user = User.new(params[:newuser])
    if @user.save
      ps = @user.create_passwords!(:invitation)
      if params[:invite]
        begin
          Mails.deliver_jury_invitation(@user, ps, :invitation)
        rescue Exception => e
          flash[:message] = "Ошибка при отправке сообщения!"
        else
          flash[:message] = "Приглашение новому члену жюри отправлено на #{@user.email}"
        end
        redirect_to :action => 'index'
        return
      end
    else
      @newuser, @user = @user, nil
    end
    
    render :action => 'index'
  end
  
  def test_message
    return access_denied unless current_user.allow?(:jury)
    begin
      Mails.deliver_test_message(params[:email])
    rescue Exception => e
      flash[:message] = "Ошибка при отправке сообщения!"
    else
      flash[:message] = "Тестовое сообщение отправлено на #{params[:email]}"
    end
    redirect_to :action => 'index'
  end
  
  def admin
    return access_denied unless current_user.allow?(:jury)
    # render :layout => 'ajax_scaffold'
  end
  
private
  
  def set_new_user
    @users = User.find(:all)
    @newuser = User.new
  end
  
end
