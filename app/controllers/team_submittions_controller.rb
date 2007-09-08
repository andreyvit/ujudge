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
    render :layout => false
  end
  
  def create
    @submittion.compiler_id = params[:submittion][:compiler_id]
    @submittion.problem_id = params[:submittion][:problem_id]
    @submittion.text = params[:submittion][:text]
    @submittion.text ||= params[:file].read
    @submittion.state = 0
    @submittion.save!
    
	  run = @submittion.runs.build(:problem_id => @submittion.problem_id, :compiler_id => @submittion.compiler_id, :team_id => @submittion.team_id)
	  run.submitted_at = Time.now
    run.penalty_time = ((run.submitted_at - @contest.started_at) / 60).to_i
	  run.state = -1
	  run.state_assigned_at = Time.now
	  run.save!
    
	  run.file_name = "#{@contest.short_name}-team#{@submittion.team_id}-#{@submittion.problem.name}-run#{run.id}.#{run.compiler.extension}"
    
	  f = File.join(UJUDGE_ROOT, 'data')
    Dir.mkdir(f) unless File.exists?(f)
	  f = File.join(UJUDGE_ROOT, 'data', @contest.short_name)
    Dir.mkdir(f) unless File.exists?(f)
	  f = File.join(UJUDGE_ROOT, 'data', @contest.short_name, 'solutions')
    Dir.mkdir(f) unless File.exists?(f)
	  f = File.join(UJUDGE_ROOT, 'data', @contest.short_name, 'solutions', run.file_name)
    
    File.open(f, 'wb') do |f|
	    f.write(@submittion.text)
    end
	  
	  run.state = 0
	  run.save!
    
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
    return if current_user.is_a?(User)
    unless @contest.state == 2
      if @contest.state == 3
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
