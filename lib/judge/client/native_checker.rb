class Judge::Client::NativeChecker

  def initialize(bin_path, spec)
    @bin_path = bin_path
    @spec = spec
  end
  
  def check(test, input_path, output_path, wdir, invoker, vfs)

    output_path = File.basename(output_path) # TODO: this assumes it's in the working dir
    answer_path = vfs.get(test.answer_file)
    cached_bin = vfs.get(@bin_path)
    local_bin = wdir.path_of(cached_bin)
    File.copy(cached_bin, local_bin)
    
    bn = File.basename(local_bin)
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
    r = Judge::Client::CheckingResult.new
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
