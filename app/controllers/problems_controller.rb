class ProblemsController < ApplicationController
  
  before_filter :set_contest
  before_filter :find_or_initialize_problem, :except => [:index]
  before_filter :set_tabs
  layout 'control'
  
  # test
  
  def index
    find_all_problems
  end
  
  def new
    @problem.set_defaults!
    respond_to do |wants|
      wants.js  { 
        render :partial => 'show_problem_editor', :locals => {:problem => @problem}
      }
      wants.html {
        render :partial => 'problem_editor', :locals => {:problem => @problem}
      }
    end
  end

  def create
    @problem.set_defaults!
    @problem.attributes = params[:problem]
    @problem.save!
    find_all_problems
    render :partial => 'problem_added', :locals => {:problem => @problem, :problems => @problems}
  rescue ActiveRecord::RecordInvalid
    render :partial => 'show_problem_editor', :locals => {:problem => @problem}
  end
  
  def update
    "sdasd"
    @problem.attributes = params[:problem]
    @problem.save!
    find_all_problems
    render :partial => 'problem_added', :locals => {:problem => @problem, :problems => @problems}
  rescue ActiveRecord::RecordInvalid
    render :partial => 'show_problem_editor', :locals => {:problem => @problem}
  end
  
  def edit
    render :partial => 'show_problem_editor', :locals => {:problem => @problem}
  end
  
private

  def find_all_problems
    @problems = @contest.problems.find(:all, :order => 'problems.letter, problems.created_at', :include => [:statements])
  end
  
  def find_or_initialize_problem
    @problem = if params[:id].blank?
      Problem.new(:contest => @contest)
    else
      @contest.problems.find(params[:id])
    end
  end
  
end
