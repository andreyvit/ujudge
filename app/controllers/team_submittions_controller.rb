class TeamSubmittionsController < ApplicationController
  
  before_filter :set_team
  before_filter :find_or_initialize_submittion
  before_filter :verify_team_access
  before_filter :set_tabs
  before_filter :verify_contest_running
    
  layout 'control'
  
  def index
    @problems = @contest.problems.find_all
    @compilers = Compiler.find_all
    
    @submittions = @team.submittions.find(:all, :order => 'submittions.id DESC')
    @runs = @team.runs.find(:all, :include => [:problem, :compiler], :order => 'runs.id DESC')
#    @stats = OpenStruct.new
#    @stats.done = Run.count(:all, :conditions => ['state = 4 or state = 3'])
#    @stats.testing = Run.count(:all, :conditions => ['state = 2'])
#    @stats.queued = Run.count(:all, :conditions => ['state = 1 or state = 0'])
#    @stats.postponed = Run.count(:all, :conditions => ['state = 10 or state = 11'])
  end
  
  def show
    access_denied unless current_user.allow?(:view_all_submittions) || current_user == @team
    @submittion.text = Server.get_submittion_text(@contest.short_name, @submittion.file_name || @submittion.runs.first.file_name)
    render :layout => false
  end
  
  def create
    team_id = @team.id
    compiler_id = params[:submittion][:compiler_id]
    problem_id = params[:submittion][:problem_id]
    text = params[:submittion][:text]
    text ||= params[:file].read
    Server.submit(team_id, problem_id, compiler_id, text)
    flash[:message] = "Решение отправлено на проверку."
    redirect_to team_submittions_url(@contest.id, @team.id)
  end
  
private

	def find_or_initialize_submittion
	  @submittion = if params[:id].blank?
	    @team.submittions.build
	  else
	    @team.submittions.find(params[:id])
	  end
	end
  
  def verify_contest_running
    return if current_user.allow?(:submit_always)
    st = (@team && @team.state_override) || @contest.state
    unless st == 2
      if st == 3
        flash[:message] = "Олимпиада окончена"
      else
        flash[:message] = "Олимпиада еще не началась"
      end
      redirect_to team_participation_url(@contest, @team)
      return false
    end
    return true
  end
  
end
