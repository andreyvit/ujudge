class TeamRatingsController < ApplicationController
  
  before_filter :set_contest
  before_filter :set_team_2
  #before_filter :verify_team_access
  before_filter :find_rating
  before_filter :set_tabs
    
  def show
    @problems = @contest.problems.find_all
    @teams = @contest.teams.find_all
    @rating = ActualResults::CalculatedRating.get(@contest, @rating_definition, @team)
  end
  
private

  def find_rating
    @rating_definition = nil #@contest.rating_definitions.find(:first)
  end
  
  def set_team_2
    @team = @contest.teams.find(params[:team_id]) if params[:team_id]
  end
  
end
