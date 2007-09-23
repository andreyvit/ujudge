ActionController::Routing::Routes.draw do |map|

  map.resources :forms do |forms|
    forms.resources :fields
  end
  
  
  map.resources :testing_queues


  # The priority is based upon order of creation: first created -> highest priority.
  
  map.home '', :controller => 'contests', :action => 'index'

  map.connect 'jury/:action', :controller => 'jury', :action => 'index'
  
    map.resource :appearance
   
    map.resource :texts
     
    map.resources :contests, :collection => {:manage => :get, :import => :post}, :member => {:export => :any} do |contests|
    contests.resource :queue, :controller => 'testing_queue', :name_prefix => 'contest_'
    contests.resource :retesting, :controller => 'retesting', :name_prefix => 'contest_'
	  contests.resources :ratings, :controller => 'team_ratings', :name_prefix => 'contest_'
    contests.resources :messages
    contests.resources :questions, :name_prefix => 'contest_', :member => {:publish => :put, :unpublish => :put, :predefinedanswer => :put} 
    contests.resources :problems do |problems|
      problems.resources :statements
      problems.resources :tests
      problems.resources :tests_uploads, :member => { :accept => :post }
    end
    contests.resources :teams, :collection => {:overview => :get, :select => :any, :update_contest_forms => :post}, :member => {:fill_forms => :any, :reset_password_for => :any} do |teams|
      teams.resources :questions, :name_prefix => 'team_', :member => {} 
      teams.resource :participation, :name_prefix => 'team_'
      teams.resources :ratings, :controller => 'team_ratings', :name_prefix => 'team_'
      teams.resources :submittions, :controller => 'team_submittions', :name_prefix => 'team_' do |submittion|  
        submittion.resource :compilation_error
      end
    end
  end
  
  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'
  map.connect ':controller/service.wsdl', :action => 'wsdl'
  
  map.connect 'cont/:action/:id', :controller => 'contests'

  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id'

end
