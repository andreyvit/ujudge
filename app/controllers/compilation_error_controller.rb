class CompilationErrorController < ApplicationController
  
  before_filter :set_team_submittion
  before_filter :set_tabs
    
  def show
    render :layout => false
  end
  
end