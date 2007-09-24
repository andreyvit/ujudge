class TeamRatingsController < ApplicationController
  
  before_filter :set_contest
  before_filter :set_team_2
  #before_filter :verify_team_access
  before_filter :find_rating
  before_filter :set_tabs
  
  helper :application
    
  def show
    unless can_see_rating?
      flash[:message] = "Рейтинг недоступен"
      redirect_to contest_url(@contest)
      return
    end
    
    @problems = @contest.problems.find_all
    @teams = @contest.teams.find_all
    @rating = ActualResults::CalculatedRating.get(@contest, @rating_definition, @team)
  end
  
  def set_access_to
    security_violation unless can_change_rating?
    @contest.rating_visibility = params[:visibility].to_i
    @contest.save!
    respond_to do |wants|
      wants.js
      wants.html { redirect_to contest_rating_url }
    end
  end
  
private

  def find_rating
    @rating_definition = nil #@contest.rating_definitions.find(:first)
  end
  
  def set_team_2
    @team = @contest.teams.find(params[:team_id]) if params[:team_id]
  end
  
  def can_change_rating?
    current_user.allow?(:change_rating)
  end
  helper_method :can_change_rating?
  
end
