module Judge
  class CheckingResult
    attr_accessor :status, :stats, :outcome, :comment, :partial_answer
  end
  
  class Checker
  end
  
  class NativeChecker < Checker

    def initialize(bin_path, spec)
      @bin_path = bin_path
      @spec = spec
    end
    
    def check(test, output_path, wdir, invoker)

      output_path = File.basename(output_path) # TODO: this assumes it's in the working dir
      input_path = test.input_file.resolve
      answer_path = test.answer_file.resolve

      bn = File.basename(@bin_path)
      local_bin = wdir.path_of(bn)
      File.copy(@bin_path, local_bin)
      
      bn = "./" + bn if !(RUBY_PLATFORM =~ /mswin32/)

      case @spec
      when 'chetvertakov.checkres', 'chetvertakov.truefalse'
        invoker.options    = [input_path, answer_path, output_path]
      when 'dyatlov.partialans'
        invoker.options    = [input_path, answer_path, output_path]
      end

      invoker.chdir      = wdir.path
      invoker.executable = bn
      invoker.capture    = :both
      
      res = invoker.invoke()
      r = CheckingResult.new
      r.status = res.reason
      return r if r.status != :ok
      
      if res.exitcode == 127
        r.status = :cannot_run
        return r
      end
      
      case @spec
      when 'chetvertakov.checkres'
        checkres = wdir.path_of('checkres')
        if File.exists?(checkres)
          File.unlink(checkres)
          r.outcome = :ok
        else
          r.outcome = :wa
        end
        r.comment = res.output
      when 'chetvertakov.truefalse'
        case res.exitcode
        when 0
          r.outcome = :ok
        else
          r.outcome = :wa
        end
      when 'dyatlov.partialans'
        case res.exitcode
        when 0
          r.outcome = :ok
          pa_line = res.output.gsub("\r", "").split("\n", 2).first
          raise "problem interpreting checker result (could not find first line)" if pa_line.nil? || pa_line.empty?
          pa_data = pa_line.split(' ', 3)[1]
          raise "problem interpreting checker result (could not parse first line)" if pa_data.nil? || pa_data.empty?
          r.partial_answer = pa_data.to_f
        else
          r.comment = res.output
          r.outcome = :wa
        end
      end
      return r
    end
  end
  
  class DiffChecker < Checker
    
    def normalize(text)
      text.strip.gsub("\r", '').split("\n").collect do |line|
        line.gsub(/\s+/, ' ').strip
      end.join("\n")
    end

    def check(test, output_path, wdir, invoker)

      input_path = test.input_file.resolve
      answer_path = test.answer_file.resolve
      
      otext = File.open(output_path, 'r') { |f| f.read }
      atext = File.open(answer_path, 'r') { |f| f.read }
      
      otext = normalize(otext)
      atext = normalize(atext)
      
      r = CheckingResult.new
      r.status = :ok
      r.outcome = if otext == atext then :ok else :wa end
      r.comment = ""
      return r
    end
  end
end