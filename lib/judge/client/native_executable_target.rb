
class Judge::Client::NativeExecutableTarget < Judge::Client::BundledTarget
  attr_reader :compiler
  
  def initialize(path, compiler)
    @path = path
    # super.initialize(path)
    @compiler = compiler
  end

  # Returns any kind of data to be passed to run_from_wdir
  def copy_runnable_to_wdir(wdir)
    found = compiler.find_binaries_in(self.path)
    compiler.copy_binaries(self.path, wdir.path, found)
    return found
  end

  # Runs this target from a working directory. +copy_runnable_to_wdir+ must have already been
  # called.
  def run_from_wdir(data, wdir, invoker)
    # note: if we're calling an interpreter, source file name is never passed;
    # if we're invoking a native executable, then we extract the first non-mask item of the binaries list
    if compiler.interpreter.nil?
      invoker.executable = compiler.binaries.each do |spec|
        res = Dir.foreach(self.path) { |filename|
          next if filename == '.' || filename == '..'
          next unless File.fnmatch(spec, filename)
          filepath = File.join(self.path, filename)
          next unless File.file?(filepath)
          break filepath
        } and break res
      end
      raise "Cannot find a binary to execute" if invoker.executable.nil?
    else
      invoker.executable = compiler.interpreter
    end
    
    invoker.chdir = wdir.path
    invoker.usewrapper = true
    # if invoker.time_limit
    #   if compiler.interpreter
    #     invoker.time_limit *= 5 
    #   else
    #     invoker.time_limit *= 2 
    #   end
    # end
    res = invoker.invoke
    res.reason = :ok if compiler.interpreter && res.reason == :runtime_error
    return res
  end

end
