
class RetestingController < ApplicationController
  current_tab :testing
  before_filter :set_contest
  before_filter :set_tabs
  before_filter :prepare_data
    
  def show
  end
  
  def create
    @selected_problems = @problems.select { |p| (params[:problems] || {}).keys.collect(&:to_i).include?(p.id) }
    @selected_compilers = @compilers.select { |c| (params[:compilers] || {}).keys.collect(&:to_i).include?(c.id) }
    if @selected_problems.empty?
      flash.now[:message] = "Выберите хотя бы одну задачу"
    elsif @selected_compilers.empty?
      flash.now[:message] = "Выберите хотя бы один язык программирования"
    else
      @runs = @contest.runs.find(:all, :conditions => {:compiler_id => @selected_compilers, :problem_id => @selected_problems})
      case params[:scope]
      when 'all'
      when 'latest'
        @runs.delete_if { |r| @runs.any? { |r2| r2.problem_id == r.problem_id && r2.team_id == r.team_id && r2.id > r.id } }
      end
      @runs.each do |run|
        new_run = Run.new(run.attributes)
        new_run.state = 0
        new_run.save!
      end
      flash[:message] = @runs.size.russian("# решение отправлено на перетестирование",
        "# решения отправлены на перетестирование", "# решений отправлены на перетестирование")
      redirect_to contest_queue_url(@contest)
      return
    end
    render :action => 'show'
  end
  
private

  def prepare_data
    @problems = @contest.problems.find(:all, :order => 'problems.letter,
      problems.created_at', :include => [:statements])
    @compilers = Compiler.find(:all)
  end
  
end
