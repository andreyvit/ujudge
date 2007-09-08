
module Judge
  class InvokationResult
    attr_accessor :reason, :output, :stats, :exitcode
    
    def initialize
      @stats = {}
    end
    
    def ok?
      @reason == :ok
    end
  end
  
  class Invoker
    attr_accessor :chdir, :executable, :options, :capture, :usewrapper, :time_limit, :memory_limit, :detect_deadlocks
    
    def reset!
      self.chdir = nil
      self.executable = nil
      self.options = []
      self.capture = :none
      self.usewrapper = false
      self.detect_deadlocks = true
      self.time_limit = nil
      self.memory_limit = nil
    end
    
    def invoke()
      if @chdir
        Dir.chdir(@chdir) do
          self.invoke2
        end
      else
        self.invoke2
      end
      
      res = InvokationResult.new
      res.output = @output
      res.exitcode = @exitcode
      if @wrapped
        res.reason = case @exitcode
        when  0   then :ok
        when  1   then :runtime_error
        when  4   then :deadlock
        when  2   then :time_limit
        when  3   then :memory_limit
        else           :failure
        end
      elsif @wrapped
        res.reason = case @exitcode
        when  0   then :ok
        when  1   then :runtime_error
        when  2   then :deadlock
        when  3   then :time_limit
        when  4   then :memory_limit
        when  5   then :user_abort
        when 10   then :run_failure
        else           :failure
        end
      else
        res.reason = :ok
      end
      return res
    end
    
    def invoke2
      cmdline = ([@executable] + @options).join(' ') + " 2>&1"
      @wrapped = false
      if self.usewrapper && RUBY_PLATFORM =~ /mswin32/
        #tl = if self.time_limit then "-t#{self.time_limit}}" else "" end
        #ml = if self.memory_limit then "-m#{self.memory_limit}}" else "" end
        #cmdline = "..\\..\\runner.cmd #{tl} #{ml} -h1 -n1 " + cmdline
        tl = if self.time_limit then "#{self.time_limit}" else "30000" end
        ml = if self.memory_limit then "#{self.memory_limit.to_i * 1024}" else "100000" end
        cmdline = "..\\..\\wkrunner.cmd #{tl} #{ml} " + cmdline
        @wrapped = true
      else
        if RUBY_PLATFORM =~ /mswin32/
          cmdline = "..\\..\\runplain.cmd " + cmdline
        else
          cmdline = "../../runplain " + cmdline
        end
      end
      puts "INVOKING #{cmdline}"
      f1 = 'exitcode'
      File.unlink(f1) if File.file?(f1)
      text = IO.popen(cmdline) do |f|
        f.read
      end
      @output = text
      @exitcode = 0
      @exitcode = File.open(f1, 'r') { |f| f.read }.to_i if File.file?(f1)
      puts "EXITCODE IS #{@exitcode}"

    end
  end
end
