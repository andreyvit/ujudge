require 'ostruct'

module Judge
  
  # compiler => javac [source]
  # extension => java
  # source_name => Task.java
  # binaries => *.class
  # interpreter => java Task.class
  
  # compiler => cl -GX -O2 -Fesol.exe [source]
  # extension => cpp
  # source_name => solution.cpp
  # binaries => sol.exe

  class BundledTarget
    attr_reader :path

    def initialize(path)
      @path = path
    end

    def exists?
      File.directory?(@path)
    end

    def create
      Dir.mkdir(@path)
    end

    def delete
      FileUtils.rmdir_r(@path)
    end

    def path_of(file)
      File.join(@path, file)
    end

  end

  class NativeExecutableTarget < BundledTarget
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
      if invoker.time_limit
        if compiler.interpreter
          invoker.time_limit *= 5 
        else
          invoker.time_limit *= 2 
        end
      end
      res = invoker.invoke
      res.reason = :ok if compiler.interpreter && res.reason == :runtime_error
      return res
    end

  end

  class Compiler
  end

  def find_java_app(cmd)

  end

  class NativeExecutableCompiler < Compiler
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
      NativeExecutableTarget.new(target_path, self)
    end

    def predict_target(source, target_path, target_name_hint = nil)
      target_name_hint ||= File.basename(source, '.*')
      target_bundle_path = File.join(target_path, target_name_hint)
      load_target(target_bundle_path)
    end

    def compile(source, target, wdir, invoker)
      raise "Target must be a NativeExecutableTarget" unless target.is_a?(NativeExecutableTarget)
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
  
  # class JavaTarget < BundledTarget
  #   # Returns any kind of data to be passed to run_from_wdir
  #   def copy_runnable_to_wdir(wdir)
  #     Dir.foreach(@path) do |file|
  #       next unless file =~ /\.class$/
  #       src_file = File.join(@path, file)
  #       wdir_file = wdir.path_of(file)
  #       File.copy(src_file, wdir_file)
  #     end
  #     return nil
  #   end
  # 
  #   # Runs this target from a working directory. +copy_runnable_to_wdir+ must have already be
  #   # called.
  #   def run_from_wdir(data, wdir, invoker)
  #     invoker.chdir = wdir.path
  #     invoker.executable = if ENV['JAVA_HOME'] then File.join(ENV['JAVA_HOME'], 'bin', 'java') else 'java' end
  #     invoker.options = "Main.class"
  #     invoker.usewrapper = true
  #     invoker.invoke
  #   end
  # 
  # end

  # class JavaCompiler < Compiler
  #   attr_accessor :extension, :executable, :source_name
  #   
  #   def initialize()
  #     @extension = 'java'
  #     @executable = "javac"
  #   end
  #   
  #   def handles?(ext)
  #     @extension === ext
  #   end
  #   
  #   def load_target(target_path)
  #     JavaTarget.new(target_path)
  #   end
  #   
  #   def predict_target(source, target_path, target_name_hint = nil)
  #     target_name_hint ||= File.basename(source, '.*')
  #     target_bundle_path = File.join(target_path, target_name_hint)
  #     JavaTarget.new(target_bundle_path)
  #   end
  #   
  #   def compile(source, target, wdir, invoker)
  #     raise "Target must be a JavaTarget" unless target.is_a?(JavaTarget)
  #     raise "Bundle already exists at #{target.path}" if target.exists?
  #   
  #     target.create
  #   
  #     base_name = File.basename(source)
  #     src = source_name || wdir.path_of(base_name)
  #     File.copy(source, src)
  #   
  #     e = @executable.gsub("[source]", src).gsub("[target]", 'executable.exe')
  #     invoker.executable, *invoker.options = e.split(' ')
  #     invoker.chdir      = wdir.path
  #     invoker.capture    = :both
  #   
  #     res = invoker.invoke()
  #   
  #     tempexe = wdir.path_of('executable.exe')
  #     # puts "exists? #{tempexe}"
  #     if File.exists?(tempexe)
  #       File.copy(tempexe, exe)
  #       return {:status => :ok, :output => res.output}
  #     else
  #       return {:status => :error, :output => res.output}
  #     end
  #   end
  # end
end
