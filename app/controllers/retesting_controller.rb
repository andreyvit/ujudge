
class RetestingController < ApplicationController
  current_tab :testing
  before_filter :set_contest
  before_filter :set_tabs
  before_filter :prepare_data
    
  def show
  end
  
  def create
    @retesting.tests = if params[:retesting][:tests].nil? then nil else 
      self.class.parse_items(params[:retesting][:tests])
    end.sort.uniq
    @retesting.tests = nil if @retesting.tests && @retesting.tests.empty?
    
    @retesting.problems = @problems.select { |p| (params[:problems] || {}).keys.collect(&:to_i).include?(p.id) }
    @retesting.compilers = @compilers.select { |c| (params[:compilers] || {}).keys.collect(&:to_i).include?(c.id) }
    
    @retesting.scope = params[:scope]
    
    if @retesting.problems.empty?
      flash.now[:message] = "Выберите хотя бы одну задачу"
    elsif @retesting.compilers.empty?
      flash.now[:message] = "Выберите хотя бы один язык программирования"
    elsif @retesting.problems.size > 1 && !@retesting.tests.nil?
      flash.now[:message] = "Нельзя указывать тесты, если выбрано несколько задач"
    else
      @runs = @contest.runs.find(:all, :conditions => {:compiler_id => @retesting.compilers, :problem_id => @retesting.problems})
      case @retesting.scope
      when 'all'
      when 'latest'
        @runs.delete_if { |r| @runs.any? { |r2| r2.problem_id == r.problem_id && r2.team_id == r.team_id && r2.id > r.id } }
      when 'latest_compilable'
        @runs.delete_if { |r| @runs.any? { |r2| r2.problem_id == r.problem_id && r2.team_id == r.team_id && r2.id > r.id && r2.outcome != 'compilation-error' } }
      end
      @runs.each do |run|
        new_run = Run.new(run.attributes)
        new_run.state = 0
        new_run.tests_filter = @retesting.tests.collect { |t| "#{t}" }.join(",") if @retesting.tests
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
    @retesting = Retesting.new
    @retesting.compilers = @compilers.dup
  end
  
  def self.parse_items(comma_separated_items)
    comma_separated_items.split(',').collect(&:strip).collect do |item|
      if item =~ /^(\d+)..(\d+)$/
        ($1.to_i .. $2.to_i).to_a
      else
        item.to_i
      end
    end.flatten.sort.uniq
  end
  
  def combine_items(items)
    result = [[]]
    items.sort.uniq.each do |item|
      if result.last.last == (item - 1)
        result.last << item
      else
        result << [item]
      end
    end
    result.collect do |ar| 
      case ar.size
      when 0 then nil
      when 1 then "#{ar.first}"
      when 2 then "#{ar.first}, #{ar.last}"
      else        "#{ar.first}..#{ar.last}"
      end
    end.compact.join(", ")
  end

  helper_method :combine_items
  
end
