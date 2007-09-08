require 'rdoc/rdoc'

class Rake::RDocTask
  # Create the tasks defined by this task lib.
  def define
    if name.to_s != "rdoc"
      desc "Build the RDOC HTML Files"
    end

    desc "Build the #{name} HTML Files"
    task name

    desc "Force a rebuild of the RDOC files"
    task paste("re", name) => [paste("clobber_", name), name]

    desc "Remove rdoc products" 
    task paste("clobber_", name) do
      rm_r rdoc_dir rescue nil
    end

    task :clobber => [paste("clobber_", name)]

    directory @rdoc_dir
    task name => [rdoc_target]
    file rdoc_target => @rdoc_files + [$rakefile] do
      rm_r @rdoc_dir rescue nil
      opts = option_list.join(' ')

      fake_argv = ['-o', @rdoc_dir] + option_list + @rdoc_files
      begin
        r = RDoc::RDoc.new
        r.document(fake_argv)
      rescue RDoc::RDocError => e
        $stderr.puts e.message
        exit(1)
      end
    end
    self
  end

end
