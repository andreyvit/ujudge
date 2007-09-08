
class RetestingController < ApplicationController
  current_tab :testing
  before_filter :set_contest
  before_filter :set_tabs
    
  def show
    @problems = @contest.problems.find(:all, :order => 'problems.letter,
      problems.created_at', :include => [:statements])
  end
end
