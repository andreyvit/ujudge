# compiler => javac [source]
# extension => java
# source_name => Task.java
# binaries => *.class
# interpreter => java Task.class

# compiler => cl -GX -O2 -Fesol.exe [source]
# extension => cpp
# source_name => solution.cpp
# binaries => sol.exe

class Judge::Client::NativeExecutableCompiler
  attr_accessor :compiler, :compiler_flags, :extension, :binaries, :source_name, :interpreter

  def initialize(rec)
    @compiler    = rec.compiler
    @extension   = rec.extension
    @binaries    = rec.binaries.split(',').collect {|s| s.strip}
    @source_name = rec.source_name
    @interpreter = rec.interpreter

    @compiler_flags = OpenStruct.new
    (rec.compiler_flags || {}).each do |key, value|
      @compiler_flags.send("#{key}=", value)
    end
    
    @compiler_flags.ignore_exit_code ||= true
  end

  def handles?(ext)
    @extension === ext # .any? {|e| ext.downcase == e }
  end

  def load_target(target_path)
    Judge::Client::NativeExecutableTarget.new(target_path, self)
  end

  def predict_target(source, target_path, target_name_hint = nil)
    target_name_hint ||= File.basename(source, '.*')
    target_bundle_path = File.join(target_path, target_name_hint)
    load_target(target_bundle_path)
  end

  def compile(source, target, wdir, invoker)
    raise "Target must be a NativeExecutableTarget" unless target.is_a?(Judge::Client::NativeExecutableTarget)
    raise "Bundle already exists at #{target.path}" if target.exists?

    target.create
    
    # copy source file to the working dir
    src = wdir.path_of(@source_name || File.basename(source))
    File.copy(source, src)

    e = @compiler.gsub("[source]", src)
    invoker.executable, *invoker.options = e.split(' ')
    invoker.chdir      = wdir.path
    invoker.capture    = :both

    res = invoker.invoke()
    
    # now find all binaries and move them to the target bundle
    found = self.find_binaries_in(wdir.path)
    
    if found.empty?
      return {:status => :error, :output => "No binaries are found. Compiler output is:\n" + res.output}
    elsif !@compiler_flags.ignore_exit_code && 0 != res.exitcode
      return {:status => :error, :output => "Non-zero compiler exit code: #{res.exitcode}. Output is:\n" + res.output}
    else
      self.copy_binaries(wdir.path, target.path, found)
      return {:status => :ok, :output => res.output}
    end
  end
  
  def find_binaries_in(dir)
    found = []
    @binaries.each do |mask|
      Dir.foreach(File.join(dir)) do |filename|
        next unless File.fnmatch(mask, filename)
        found << filename
      end
    end
    return found
  end
  
  def copy_binaries(src_dir, dst_dir, found)
    found.each do |filename|
      src = File.join(src_dir, filename)
      dst = File.join(dst_dir, filename)
      File.copy(src, dst)
    end
  end
end
