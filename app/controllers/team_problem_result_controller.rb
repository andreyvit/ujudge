
class TeamProblemResultController < ApplicationController
  
  before_filter :set_problem
  before_filter :set_tabs
  
  layout nil
  
  def show
    @rating = ActualResults::CalculatedRating.get(@contest, nil, @team)
    @submittion = @rating.teams[@team.id].submittions[@problem.id]
  end
  
  def set_problem
    set_contest
    @team = @contest.teams.find(params[:team_id])
    @problem = @contest.problems.find(params[:problem_id])
  end
  
end
