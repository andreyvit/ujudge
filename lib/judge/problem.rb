
class Judge::Problem
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
    @fspath = File.join('problems', "#{@id}")
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
      dir = File.join(UJUDGE_ROOT, 'data', @fspath)
      if File.directory?(dir)
        Dir.foreach(dir) do |file|
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
        @tests = @tests.collect do |info|
          if info[0] && info[1] && ans_map[info[0]]
            Judge::Test.new(self, info[0], info[1], ans_map[info[0]]) 
          else
            # TODO: signal an error!
            nil
          end
        end.compact
        read_points
      end
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
        @checker = Judge::Client::NativeChecker.new(f, check_methods[@check_method])
      when 2 # internal diff checker
        @checker = Judge::Client::DiffChecker.new
      else
        raise "unknown checker type"
      end
    end
    @checker
  end
  
private

  def read_points
    dir = File.join(UJUDGE_ROOT, 'data', @fspath)
    fn = File.join(dir, 'points.txt')
    if File.file?(fn)
      index = 1
      File.open(fn, 'r') do |f| 
        f.each_line do |line|
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
        end
      end
    else
      any_points = false
      Dir.foreach(dir) do |file|
        next if file == '.' || file == '..'
        case file 
        when /^(\d+)(\.pts)?$/
          t = @tests.find { |t| t.ord == $1.to_i }
          raise "points file #{file} does not correspond to any test" if t.nil?
          pts_string = File.open(File.join(dir, file), 'r') { |f| f.read }
          points, extra = pts_string.split(' ', 2)
          t.points = points.to_i
          any_points = true
        end
      end
      return unless any_points
    end
    
    # now check for tests that weren't assigned any points
    lost_tests = @tests.select { |test| test.points.nil? }
    raise "no points assigned to test(s) #{lost_tests.join(", ")}" unless lost_tests.empty?
  end

end
