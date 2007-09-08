require_dependency "user"

# Password's reason field can contain the following values:
#   :initial, :change, :forgot
module LoginSystem 
  
  module Principal
    
  private
    
  end

  def included(base) 
    base.class_eval <<-E
      helper_method :current_user
      helper_method :logged_in?
    E
  end  
  
protected
  
  def current_user
    session['user'] ||= AnonymousUser.new
  end
  
  def authorize?
    true
  end
  
  def logged_in?
    !(session['user'].nil? || session['user'].is_a?(AnonymousUser))
  end
  
  def login_required
    if logged_in? && authorize?
      return true
    end

    store_location
  
    access_denied_without_login
    return false 
  end

  # overwrite if you want to have special behavior in case the user is not authorized
  # to access the current operation. 
  # the default action is to redirect to the login screen
  # example use :
  # a popup window might just close itself for instance
  def access_denied_without_login
    render :partial => 'errors/access_denied', :status => 403, :layout => 'application'
  end  
  
  # store current uri in  the session.
  # we can return to this location by calling return_location
  def store_location
    session['return-to'] = @request.request_uri
  end

  # move to the last store_location call or to the passed default one
  def redirect_back_or_default(default)
    if session['return-to'].nil?
      redirect_to default
    else
      redirect_to_url session['return-to']
      session['return-to'] = nil
    end
  end

end