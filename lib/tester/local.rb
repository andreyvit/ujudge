
require 'tester/tester'
require 'pathname'

module Judge
  class LocalFile
    attr_reader :path
    
    def initialize(path)
      @path = path
    end
    
    def resolve
      return File.join(UJUDGE_ROOT, @path)
      # if RUBY_PLATFORM =~ /mswin32/
      #   return p
      #   p = p.gsub(/^\/?(\w:)/, '/\1')
      #   puts "!!!!#{p}"
      #   p = Pathname.new(p).realpath.to_s
      #   p = p.gsub(/^\/(\w)/, '\1:')
      #   return p
      # else
      #   return Pathname.new(p).realpath.to_s
      # end
    end
  end
  
  class Solution
    attr_reader :id, :source_file, :source_text, :compiler, :problem
    
    def initialize(run)
      @id = run.id
      contest = run.problem.contest
      @source_file = LocalFile.new(File.join('data', contest.short_name, 'solutions', run.file_name))
      @source_text = File.open(@source_file.resolve, 'r') { |f| f.read }
      @problem = Problem.new(run.problem)
      
      @compiler = Judge::NativeExecutableCompiler.new(run.compiler)
    end
    
    def unique_name(context)
      "run#{id}"
    end
  end

  class Problem
    attr_reader :id, :input_file_name, :output_file_name, :fspath, :time_limit, :memory_limit
    
    def initialize(problem)
      @input_file_name = problem.input_file
      @output_file_name = problem.output_file
      @check_method = problem.check_method
      @time_limit = problem.time_limit
      @memory_limit = problem.memory_limit
      puts "found check method #{@check_method} for problem #{problem.name}"
      @name = problem.name
      @id = problem.id
      @fspath = File.join('data', problem.contest.short_name, 'problems', @name)
      checker # fetch info
    end
    
    def unique_name(context)
      @name || "problem#{id}"
    end
    
    def tests
      if @tests.nil?
        @tests = []
        ans_map = {}
        # puts "searching in #{@fspath}"
        Dir.foreach(@fspath) do |file|
          next if file == '.' || file == '..'
          # puts "checking #{file}"
          case file 
          when /^(\d+)(\.in)?$/
            @tests << [$1.to_i, file]
          when /^(\d+)(\.out|\.ans|\.a)$/
            ans_map[$1.to_i] = file
          end
        end
        @tests.sort { |a, b| a[0] <=> b[0] }
        @tests = @tests.collect { |info| Test.new(self, info[0], info[1], ans_map[info[0]]) }
        read_points
      end
      @tests
    end
    
    def checker
      if @checker.nil?
        case @check_method
        when 1, 3, 4 # native checker
          f = File.join(@fspath, 'checker.exe')
          check_methods = {
            1 => 'chetvertakov.checkres',
            3 => 'chetvertakov.truefalse',
            4 => 'dyatlov.partialans',
          }
          puts "found native checker of type #{check_methods[@check_method]}"
          @checker = Judge::NativeChecker.new(f, check_methods[@check_method])
        when 2 # internal diff checker
          @checker = Judge::DiffChecker.new
        else
          raise "unknown checker type"
        end
      end
      @checker
    end
    
  private
  
    def read_points
      fn = File.join(@fspath, 'points.txt')
      return unless File.file?(fn)
      index = 1
      File.open(fn, 'r') do |f| f.each_line do |line|
        points, extra = line.split(' ', 2)
        test_name = "#{index}"
        index += 1
        test_name = File.basename(test_name, '.*') if test_name.include?('.')
        nr = test_name.to_i
        @tests.each do |test|
          next unless test.ord == nr
          test.points = points # TODO: data type cast?
          break true
        end or throw "#{fn}: test #{test_name} (interpreted as test #{nr}) not found"
      end end
      
      # now check for tests that weren't assigned any points
      lost_tests = []
      @tests.each do |test|
        lost_tests << test.ord.to_s if test.points.nil?
      end
      throw "#{fn}: no points assigned to test(s) #{lost_tests.join(", ")}" unless lost_tests.empty?
    end
  
  end
  
  class Test
    attr_reader :problem, :ord, :input_file, :answer_file
    attr_accessor :points
    
    def initialize(problem, ord, input_file_name, answer_file_name)
      @problem = problem
      @ord = ord
      @input_file  = LocalFile.new(File.join(@problem.fspath, input_file_name))
      puts input_file_name
      @answer_file = LocalFile.new(File.join(@problem.fspath, answer_file_name))
    end
    
    def unique_name(context)
      "#{@problem.unique_name(context)}.test#{sprintf("%02d", @ord)}"
    end
  end  
  
  class LogReporter
    
    def initialize(logger)
      @log = logger
    end
    
    def start(solution)
      @log.puts "start processing of #{solution.unique_name(:global)}"
    end
    
    def compiling
      @log.puts "compiling"
    end
    
    def compilation_error(output)
      @log.puts "compilation error, compiler output is:"
      @log.puts output
    end
    
    def testing(test)
      @log.puts "testing on test #{test.unique_name(:solution)}"
    end
    
    def invokation_error(reason)
      @log.puts "invokation error: #{reason}"
    end
    
    def invokation_finished(stats)
      @log.puts "invokation finished."
    end
    
    def checking
      @log.puts "checking"
    end
    
    def checking_problem(reason)
      @log.puts "checker problem: #{reason}."
    end
    
    def checking_finished(result, stats)
      @log.puts "checking done: #{result}."
    end

    def finished
      @log.puts "finished."
    end
    
  end
end
