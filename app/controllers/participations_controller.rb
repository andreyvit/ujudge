class ParticipationsController < ApplicationController
  
  before_filter :set_team
  before_filter :verify_team_access
  before_filter :set_tabs
    
  layout 'control'
  
  def show
    @messages = @contest.messages.find(:all, :order => 'messages.created_at DESC')
  end
  
private


end
