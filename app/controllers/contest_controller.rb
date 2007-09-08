
require 'file_utils'

class GrandResults
  attr_accessor :problems
  attr_accessor :runs
  attr_accessor :runres
  attr_reader :teamres
  attr_reader :problem_tests
  
  def initialize
    @runres = {}
    @problems = []
    @runs = []
    @problem_tests = {}
    @teamres = {}
  end
end

class TeamResult
  attr_accessor :place, :points
end

class RunResult
  attr_reader :probres
  attr_accessor :place, :points
  
  def initialize
    @probres = {}
    @points = 0
  end
end

class RunProblemResult
  attr_accessor :points
  attr_accessor :place
  attr_accessor :tests
  
  def initialize
    @tests = {}
  end
end

class ContestController < ApplicationController
  include ContestAcceptor

  before_filter :login_required, :except => [:index]
  
  def index
    accept_contest
    
    @teams = @contest.teams
  end
  
  def submit
    accept_contest
    @problems = @contest.problems
    @compilers = Compiler.find(:all)
    @submittion = Submittion.new
    if current_user.is_a?(Team)
      @submittion.team_id = current_user.id
    else
      @submittion.team_id = Team.find(:first).id
    end
    
    if request.post?
      @submittion.attributes = params[:submittion]
      
      run = Run.new(:problem_id => @submittion.problem_id, :compiler_id => @submittion.compiler_id, :team_id => @submittion.team_id)
      run.submitted_at = Time.now
      run.state = -1
      run.state_assigned_at = Time.now
      run.save!
      
      run.file_name = "#{@contest.short_name}-team#{@submittion.team_id}-#{@submittion.problem.name}-run#{run.id}.#{run.compiler.extension}"
      f = File.join(UJUDGE_ROOT, 'data', @contest.short_name, 'solutions', run.file_name)
      File.open(f, 'w') do |f|
        f.write(@submittion.text)
      end
      
      run.state = 0
      run.save!

      flash[:message] = "Решение отправлено на проверку."
      redirect_to :action => 'queue'
    end
  end
  
  def submit_incoming
    accept_contest
    
    incdir = File.join(UJUDGE_ROOT, 'incoming')
    
    filelistpath = File.join(incdir, 'filelist')
    langs = {}
    File.open(filelistpath, 'r') do |file|
      file.each_line do |line|
        fname, lang = line.split(' ', 2)
        fname.strip!
        lang.strip!
        langs[fname] = lang
      end
    end
    
    @unparsed = []
    @problems = []
    @success = []

    langs_map = {'fpas' => Compiler.find(4), 'vcc' => Compiler.find(3), 'delphi' => Compiler.find(7), 'java' => Compiler.find(8), 'mingw' => Compiler.find(5)}
    problem_map = {601 => Problem.find(3), 602 => Problem.find(4), 603 => Problem.find(1)}
    
    list = []
    Dir.foreach(incdir) do |filename|
      filepath = File.join(incdir, filename)
      
      unless filename =~ /^(\d+)-(\d+)-(\d+)-(\d+)\.(\w+)$/
        @unparsed << filename unless filename == 'filelist'
        next
      end
      
      team_id = $1.to_i
      problem_id = $2.to_i
      submit_time = ($3 + $4)
      
      next unless (601..603) === problem_id
      
      problem = problem_map[problem_id]
      if problem.nil?
        @problems << "cannot find problem #{problem_id}"
        next
      end
      
      team = Team.find_by_id(team_id)
      if team.nil?
        @problems << "cannot find team #{team_id}"
        next
      end
      
      lang = langs_map[langs[filename]]
      if lang.nil?
        @problems << "cannot find lang #{langs[filename]}"
        next
      end
      
      list << OpenStruct.new(:team => team, :lang => lang, :problem => problem, :filename => filename, :submit_time => submit_time)
    end
    list.sort { |a,b| a.submit_time <=> b.submit_time }
    hash = {}
    list.each do |item|
      h1 = (hash[item.team] ||= {})
      h1[item.problem] = item
    end
    
    hash.each do |team, subhash|
      subhash.each do |problem, item|
        unless params[:submit].nil?
          run = Run.new(:problem_id => item.problem.id, :compiler_id => item.lang.id, :team_id => item.team.id)
          run.submitted_at = Time.now
          run.state = -1
          run.state_assigned_at = Time.now
          run.origin_info = item.filename
          run.save!

          run.file_name = "#{@contest.short_name}-team#{item.team.id}-#{item.problem.name}-run#{run.id}.#{run.compiler.extension}"
          f = File.join(UJUDGE_ROOT, 'data', @contest.short_name, 'solutions', run.file_name)
          File.copy(File.join(incdir, item.filename), f)

          run.state = 0
          run.save!
        end
        
        unless params[:export].nil?
          efilename = File.join(UJUDGE_ROOT, 'outgoing', item.filename)
          File.copy(File.join(incdir, item.filename), efilename)
        end

        @success << "team #{item.team.name}, language #{item.lang.display_name}, problem #{item.problem.display_name}, src file #{item.filename}"
      end
    end
  end
  
  def queue
    accept_contest
    
    @runs = Run.find(:all, :conditions => ['problems.contest_id = ?', @contest.id], :include => [:problem, :compiler, :team], :order => 'runs.id DESC')
    @stats = OpenStruct.new
    @stats.done = Run.count(:all, :conditions => ['state = 4 or state = 3'])
    @stats.testing = Run.count(:all, :conditions => ['state = 2'])
    @stats.queued = Run.count(:all, :conditions => ['state = 1 or state = 0'])
    @stats.postponed = Run.count(:all, :conditions => ['state = 10 or state = 11'])
  end
  
  def retest
    accept_contest
    @run = Run.find(params[:run_id])
    # @run.tests.delete_all
    @run.state = 0
    @run.save!

    flash[:message] = "Решение будет перетестировано."
    flash[:highlight] = @run.id
    redirect_to :action => 'queue'
  end
  
  def run_results
    accept_contest
    @run = Run.find(params[:run_id])
    @tests = @run.tests.find(:all, :include => [])
  end
  
  def details
    accept_contest
    @run = Run.find(params[:run_id])
    @details = @run.details
  end
  
  def view_source
    accept_contest
    @run = Run.find(params[:id])
    f = File.join(UJUDGE_ROOT, 'data', @contest.short_name, 'solutions', @run.file_name)
    render(:text => File.open(f, 'r') { |f| f.read }, :content_type => "text/plain")
  end
  
  def pa_lesseq(a,b)
    return true if !b.succeeded? || b.partial_answer.nil?
    return false if !a.succeeded? || a.partial_answer.nil?
    x = a.partial_answer.to_f
    y = b.partial_answer.to_f
    return x <= y + 0.000001
  end
  
  # def rating
  #   accept_contest
  #   
  #   run_ids = Run.find_by_sql(["SELECT MAX(r.id) as id FROM runs r INNER JOIN teams t ON r.team_id = t.id WHERE t.contest_id = ? AND r.state IN (3,4) AND problem_id = 1 GROUP BY r.team_id, r.problem_id", @contest.id])
  #   @runs = Run.find(run_ids.collect {|r| r.id}, :include => [:tests, :problem])
  #   
  #   # sort them by problem
  #   rp = {}
  #   @runs.each { |run| (rp[run.problem_id] ||= []) << run }
  #   
  #   @grand_results = GrandResults.new
  #   rp.each do |problem_id, pruns|
  #     problem = Problem.find(problem_id) # yeah, really could be more efficient
  #     @grand_results.problems << problem
  #     pruns.each { |run| @grand_results.runs << run } if @grand_results.runs.empty?
  #     
  #     case problem.scoring_method
  #     when 'partial_answers'
  #       # RAILS_DEFAULT_LOGGER.info ""
  #       # walk each test and sort the places; this is a bit trickier than it should be due to DB structure
  #       # sort by tests first
  #       rt = {}
  #       pruns.each do |run|
  #         run.tests.each { |test| (rt[test.test_ord] ||= []) << OpenStruct.new(:run => run, :test => test) }
  #       end
  # 
  #       sum_points = {}
  #       points = {}
  #       rt.each do |test_ord, infos|
  #         infos.each do |info|
  #           run = info.run
  #           test = info.test
  #           pts = infos.inject(0) { |sum, info2| sum + if pa_lesseq(info2.test, test) then 1 else 0 end }
  #           (points[run] ||= {})[test_ord] = OpenStruct.new(:pts => pts, :test => test)
  #           sum_points[run] ||= 0
  #           sum_points[run] += pts
  #         end
  #       end
  #       
  #       # sum_points.each {|run, sum| (grand_total[run] ||= 0) += }
  #       sum_points.each do |run, sum| 
  #         rr = @grand_results.runres[run] ||= RunResult.new
  #         rpr = (rr.probres[problem] ||= RunProblemResult.new)
  #         rpr.points = sum
  #         rpr.place = sum_points.inject(1) {|cursum, x| cursum + if x[1] < sum then 1 else 0 end  }
  #         points[run].each do |test_ord, pts|
  #           rpr.tests[test_ord] = pts
  #           ptt = (@grand_results.problem_tests[problem] ||= [])
  #           ptt << test_ord unless ptt.include?(test_ord)
  #         end
  #         rr.points += rpr.place
  #       end
  #       
  #       @grand_results.runres.sort {|a,b| a[1].points <=> b[1].points}
  #       @grand_results.runres.each do |key, runres|
  #         runres.place = @grand_results.runres.inject(0) { |sum, rr|
  #           rr1, rr2 = *rr
  #           sum + if
  #               rr2.points <
  #                 runres.points then 1 else 0 end
  #       }
  #     when 'points'
  #       pruns.each do |run|
  #         rr = @grand_results.runres[run] ||= RunResult.new
  #         rr.place = pruns.inject(0) { |sum, xxrun| sum + if xxrun.points < run.points then 1 else 0 end }
  #       end
  #     end
  #   end
  #   
  #   
  #   @contest.teams.each do |team|
  #     
  #   end
  # end
  
  def run_state_func(run)
    if run.state == 3 || run.state == 4 then 
      if run.points.nil?
        0
      else
        run.points
      end
    else
      -1000
    end
  end
  
  def overall_test_results
    accept_contest
    
    run_ids = Run.find_by_sql(["SELECT MAX(r.id) as id FROM runs r INNER JOIN teams t ON r.team_id = t.id WHERE t.contest_id = ? GROUP BY r.team_id, r.problem_id", @contest.id])
    all_runs = Run.find(run_ids.collect {|r| r.id}, :include => [:tests, :problem])
    
    @tests = {}
    @runs = {}
    @mode = params['mode'] || 'jury'
    
    modes = {'jury' => {:show_team_id => true, :show_compiler => true},
      'export' => {:show_team_id => false, :show_compiler => false}}
    @info = modes[@mode] || modes['jury']
  
    @problems = @contest.problems.find(:all)
    @problems.each do |problem|
      prob_tests = RunTest.find_by_sql("SELECT test_ord FROM run_tests rt INNER JOIN runs r ON rt.run_id = r.id WHERE problem_id = #{problem.id} GROUP BY test_ord")
      @tests[problem.id] = prob_tests.collect { |pt| pt.test_ord.to_i }.sort
      @runs[problem.id] = all_runs.select { |r| r.problem_id == problem.id }.sort {|a,b| run_state_func(b) <=> run_state_func(a)}
    end
  end
end
