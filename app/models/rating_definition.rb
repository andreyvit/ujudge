class RatingDefinition < ActiveRecord::Base
  belongs_to :contest
  
  has_many :ratings
  
  serialize :options
  
  def recalculate!
    m = self.options['method']
    self.send("calculate_#{m}")
  end
  
  SCOPE_TYPES = ['contest', 'problem', 'test']
  
  def inner_scope_type
    SCOPE_TYPES[SCOPE_TYPES.index(self.scope_type)+1]
  end
  
  def parent_scope_type
    SCOPE_TYPES[SCOPE_TYPES.index(self.scope_type)+1]
  end
  
private

  def calculate_sort_by_partial_ans
    s = self.options['sorting']
    ipol = self.options['invalid_policy']

    # every rating needs a set of teams
    teams = self.contest.teams.find(:all)
    teams_by_id = {}
    teams.each { |t| teams_by_id[t.id] = t }

    # rank runs by partial answers, scope must be test
    raise "only 'test' scope is supported for method #{m}" unless self.scope_type == 'test'
    
    # load the latest runs for this problem
    problem = Problem.find(self.parent_scope_id)
    run_ids = Run.find_by_sql(["SELECT MAX(r.id) as id FROM runs r INNER JOIN teams t ON r.team_id = t.id WHERE t.contest_id = ? AND r.state = 4 AND problem_id = ? GROUP BY r.team_id, r.problem_id", self.contest_id, problem.id])
    runs = Run.find(run_ids.collect {|r| r.id}, :include => [:tests])
    
    # find out which tests exist (and load them )
    test_ordinals = Set.new
    runs.each do |run| 
      next unless run.has_test_results?
      run.tests.each { |t| test_ordinals << t.test_ord }
    end
    
    # create a set of runs for each team
    team_runs = {}
    teams_with_at_least_one_success = Set.new
    teams.each do |team|
      r = runs.find {|run| run.team_id == team.id}
      if r.nil?
        r = RunStub.new
      end
      team_runs[team] = r
      teams_with_at_least_one_success << team if !r.is_a?(RunStub) && r.tests.any? { |test| test.succeeded? }
    end
          
    # for each test, sort the teams
    test_ordinals.each do |test_ord|
      # find test result for each team
      team_tests = {}
      team_runs.each do |team, run|
        t = if run.is_a?(RunStub) then nil else run.tests.to_a.find { |test| test.test_ord == test_ord } end
        t = RunTestStub.new(:successes_exist => teams_with_at_least_one_success.include?(team) && team.name !~ /Altai/i, :outcome => t.outcome) if !t.nil? && t.partial_answer.nil?
        t = RunTestStub.new(:successes_exist => teams_with_at_least_one_success.include?(team) && team.name !~ /Altai/i) if t.nil?
        team_tests[team] = t
      end
      
      # RAILS_DEFAULT_LOGGER.debug team_tests.to_yaml
      
      ur = Set.new
      # sort teams by results
      resultset = teams.collect do |team| 
        {
          :team_id => team.id,
          # :test_id => if team_tests[team].is_a?(RunTestStub) then nil else team_tests[team].id end, 
          :partial_answer => team_tests[team].partial_answer,
          :outcome => team_tests[team].outcome,
          :place => self.send("calculate_place_#{s}", team_tests.values, team_tests[team]) { |a,b| compare_test_results(a,b) }
          # :test => team_tests[team]
        }
      end
      resultset.each do |r| ur << r[:place] end
      RAILS_DEFAULT_LOGGER.debug "PLACES: " + ur.to_a.join(', ')
      # resultset.sort { |a, b| compare_test_results(team_tests[a], team_tests[b]) }
    
      resultset.sort! { |a,b| compare_resultset_places(a,b,teams_by_id) }
      
      Rating.set!(self, test_ord, resultset)
    end
    
    case ipol
    when 'skip'
      # treat all invalid runs as nonexistent, this is easy
    when 'bonus_if_any_valid'
      # check to see whether any runs of the team are valid; if yes, give a bonus to invalid runs
    end
  end
  
  def calculate_places_from_points
    s = self.options['sorting']
    ipol = self.options['invalid_policy']

    # every rating needs a set of teams
    teams = self.contest.teams.find(:all)
    teams_by_id = {}
    teams.each { |t| teams_by_id[t.id] = t }

    # rank runs by total points, scope must be test
    raise "only 'problem' scope is supported for this method" unless self.scope_type == 'problem'
    
    # load the latest runs for this problem
    problem = Problem.find(problem_id = self.parent_scope_id)
    run_ids = Run.find_by_sql(["SELECT MAX(r.id) as id FROM runs r INNER JOIN teams t ON r.team_id = t.id WHERE t.contest_id = ? AND r.state = 4 AND problem_id = ? GROUP BY r.team_id, r.problem_id", self.contest_id, problem_id])
    runs = Run.find(run_ids.collect {|r| r.id})
    
    # create a set of runs for each team
    team_runs = {}
    teams.each do |team|
      r = runs.find {|run| run.team_id == team.id}
      if r.nil? || r.points.nil?
        r = RunStub.new
      end
      team_runs[team] = r
    end
          
    resultset = teams.collect do |team| 
      {
        :team_id => team.id,
        # :test_id => if team_tests[team].is_a?(RunTestStub) then nil else team_tests[team].id end, 
        :points => team_runs[team].points,
        :place => self.send("calculate_place_#{s}", team_runs.values, team_runs[team]) { |a,b| compare_run_points(a,b) }
      }
    end
    
    resultset.sort! { |a,b| compare_resultset_places(a,b,teams_by_id) }
    
    Rating.set!(self, problem_id, resultset)
    
    case ipol
    when 'skip'
      # treat all invalid runs as nonexistent, this is easy
    when 'bonus_if_any_valid'
      # check to see whether any runs of the team are valid; if yes, give a bonus to invalid runs
    end
  end

  def calculate_places_from_subratings
    s = self.options['sorting']

    # every rating needs a set of teams
    teams = self.contest.teams.find(:all)
    teams_by_id = {}
    teams.each { |t| teams_by_id[t.id] = t }

    inner_scope = case self.scope_type
    when 'problem'
      'test'
    when 'contest'
      'problem'
    else
      raise "scope '#{self.scope_type}' is not supported for this method"
    end
    
    # load all inner ratings
    conds = ['contest_id = ? AND scope_type = ?', self.contest_id, inner_scope]
    ratings = Rating.find(:all, :conditions => conds, :include => [:rating_definition])
    
    # group by parent_scope_id (will be nil for problem-level inner ratings)
    ratings_by_parent = {}
    ratings.each do |rating|
      ps = rating.rating_definition.parent_scope_id
      ps = nil if rating.rating_definition.scope_type == 'problem' # XXX hack to cope with another hack
      ratings_by_parent[ps] ||= []
      ratings_by_parent[ps] << rating.value
    end
    
    ratings_by_parent.each do |parent_id, rating_values|
      # sum the points for each team
      team_points = {}
      rating_values.each do |rv|
        rv.each do |info|
          team_points[info[:team_id]] = (team_points[info[:team_id]] || 0) + info[:place]
        end
      end
      
      # RAILS_DEFAULT_LOGGER.debug "all points:\n" + team_points.to_yaml

      # assign places
      resultset = teams.collect do |team| 
        raise "no points for team #{team.id}" if team_points[team.id].nil?
        {
          :team_id => team.id,
          :points => team_points[team.id],
          :place => self.send("calculate_place_#{s}", team_points.values, team_points[team.id]) { |a,b| (b <=> a) }
        }
      end
      
      resultset.sort! { |a,b| compare_resultset_places(a,b,teams_by_id) }
      
      Rating.set!(self, parent_id, resultset)
    end
  end
  
  def compare_resultset_places(x,y,teams_by_id) 
    return x[:place] <=> y[:place] if x[:place] != y[:place]
    return teams_by_id[x[:team_id]].name <=> teams_by_id[y[:team_id]].name
  end

  def calculate_place_less(all, curitem)
    raise "block required" unless block_given?
    all.inject(1) { |sum, item| sum + if yield(item, curitem) > 0 then 1 else 0 end }
  end

  def calculate_place_lesseq(all, curitem)
    raise "block required" unless block_given?
    all.inject(0) { |sum, item| sum + if yield(item, curitem) >= 0 then 1 else 0 end }
  end

  def compare_test_results(x, y)
    if x.is_a?(RunTestStub) && y.is_a?(RunTestStub)
      return 0 if x.successes_exist && y.successes_exist
      return 1 if x.successes_exist
      return -1 if y.successes_exist
      return 0
    end
    return -1 if x.is_a?(RunTestStub)
    return 1 if y.is_a?(RunTestStub)
    
    throw "impossible" if x.partial_answer.nil? || y.partial_answer.nil?
    
    return y.partial_answer.to_f <=> x.partial_answer.to_f
  end

  def compare_run_points(x, y)
    return 0 if x.is_a?(RunStub) && y.is_a?(RunStub)
    return -1 if x.is_a?(RunStub)
    return 1 if y.is_a?(RunStub)
    
    return 0 if x.points.nil? && y.points.nil?
    return -1 if x.points.nil?
    return 1 if y.points.nil?
    
    return x.points.to_f <=> y.points.to_f
  end
  
  # def foo
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
  # end
end
