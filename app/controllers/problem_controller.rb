class ProblemsController < ApplicationController
  include ContestAcceptor
  
  def index
    accept_contest
    @problems = @contest.problems
  end
  
end
