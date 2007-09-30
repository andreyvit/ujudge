
class Judge::Server::ProcessTestsUploadJob < Judge::Server::Job
  
  class DirInfo
    attr_reader :name, :display_name, :tests, :leftover
    attr_accessor :checker_file
    
    def initialize(name)
      @name = name || ""
      @display_name = name || "/"
      @tests = {}
      @leftover = []
      @checker_file = nil
    end
    
    def test(position)
      @tests[position] ||= TestInfo.new(position)
    end
    
    def append(file_name)
      return file_name if @name.size == 0
      return File.join(@name, file_name)
    end
  end
  
  class TestInfo
    attr_accessor :input, :answer, :pts
    attr_reader :position
    
    def initialize(position)
      @position = position
    end
  end

  def initialize(server, upload_id)
    @server = server
    @upload_id = upload_id
  end

  def run
    begin
	    tests_upload = TestsUpload.find(@upload_id)
      fname = File.join(UJUDGE_ROOT, tests_upload.filename)
      case tests_upload.state
      when 1
        preprocess_tests_zip(tests_upload, fname)
      when 3
        process_tests_zip(tests_upload, fname)
      end
    rescue
      puts "Exception processing zip file: #{$!}"
      puts $!.backtrace
    end
  end
  
  def preprocess_tests_zip(tests_upload, fname)
    puts "preprocessing #{fname}"

    dirs = nil
    Zip::ZipFile.open(fname) do |zip|
      dirs = collect_tests_in(zip, fname)
    end
    
    # find directories with tests
    dirs_with_tests = dirs.values.select { |d| d.tests.size > 0 }
    problem_id_to_tests_directories = {}

    contest = Contest.find(tests_upload.contest_id)
    problems = contest.problems.find(:all)

    errors = []
    warnings = []
    
    puts "found #{dirs.size} dirs: #{dirs.values.collect {|d| "#{d.name} (#{d.tests.size})"}.join(", ")}"
    
    case 
    when dirs_with_tests.size == 0
      errors << "Ни в одной директории тесты не обнаружены."
    when dirs_with_tests.size == 1 && tests_upload.problem_id != nil
      (problem_id_to_tests_directories[tests_upload.problem_id] ||= []) << dirs_with_tests.first
    else
      dirs_with_tests.each do |dir|
        possible_problems = []
        dir.name.split('/').each do |name_component|
          chosen_problem = problems.each do |problem|
            break problem if problem.letter && problem.letter === name_component
            break problem if problem.name && problem.name === name_component
            break problem if problem.display_name && problem.display_name === name_component
          end
          possible_problems << chosen_problem unless chosen_problem.is_a?(Array)
        end
        
        if possible_problems.empty?
          errors << "В директории #{dir.display_name} обнаружены тесты, но не получилось определить, к какой задаче они относятся. Пожалуйста, уточните путь к этой директории, чтобы в нем содержалось либо короткое название, либо буква ровно одной задачи."
          next
        end
        (problem_id_to_tests_directories[possible_problems.first.id] ||= []) << dir and next if possible_problems.size == 1
        possible_problem_names = possible_problems.collect { |p| p.extra_name }.join(", ")
        errors << "Директория #{dir.display_name} может соответствовать задачам #{possible_problem_names}. Пожалуйста, уточните путь к этой директории, чтобы в нем содержалось либо короткое название, либо буква ровно одной задачи."
      end
    end
    
    problem_id_to_tests_directory = {}
    problem_id_to_tests_directories.each do |problem_id, tests_dirs|
      problem_id_to_tests_directory[tests_dirs.first.name] = problem_id and next if tests_dirs.size <= 1
      problem = problems.find { |p| p.id == problem_id }
      dir_names = tests_dirs.collect { |d| d.display_name }.join(", ")
      errors << "Для задачи #{problem.extra_name} найдены тесты в нескольких директориях: #{dir_names}. Пожалуйста, оставьте только одну директорию с тестами для этой задачи."
    end
    
    dirs.values.each do |dir|
      next if dir.tests.size > 0
      next if dirs_with_tests.any? { |d| d.name.starts_with?(dir.name) }
      warnings << "В директории #{dir.name} тесты не обнаружены (или имеют неправильные названия)."
    end
    
    result = OpenStruct.new
    result.errors = errors
    result.warnings = warnings
    result.problem_id_to_tests_directory = problem_id_to_tests_directory
    puts "processed, found #{problem_id_to_tests_directory.size} mappings, #{errors.size} errors, #{warnings.size} warnings"
    tests_upload.message = YAML.dump(result)
    tests_upload.state = 2
    tests_upload.save!
  end

  
  def process_tests_zip(tests_upload, fname)
    puts "processing #{fname}"
    result = YAML.load(tests_upload.message)
    problem_id_to_tests_directory = result.problem_id_to_tests_directory

    # contest = Contest.find(tests_upload.contest_id)
    # problems = contest.problems.find(:all)

    dirs = nil
    Zip::ZipFile.open(fname) do |zip|
      dirs = collect_tests_in(zip, fname)
      dirs.values.each do |dir|
        problem_id = problem_id_to_tests_directory[dir.name || ""]
        # problem = problems.find { |p| p.id == problem_id }
        unless problem_id.nil?
          path = File.join(UJUDGE_ROOT, 'data', 'problems', "#{problem_id}")
          FileUtils.rmdir_r(path) rescue nil
          File.makedirs(path)
          dir.tests.each do |pos, test|
            [test.input, test.answer, test.pts].each do |file_name|
              next if file_name.nil?
              file_name = File.split(file_name).last
              puts "Trying #{file_name} in #{path}, zip dir #{dir} (exists: #{File.directory?(path) ? "yes" : "no"})"
              File.open(File.join(path, file_name), 'wb') { |f| f.write(zip.read(dir.append(file_name))) }
            end
          end
          unless dir.checker_file.nil?
            File.open(File.join(path, dir.checker_file), 'wb') { |f| f.write(zip.read(dir.append(dir.checker_file))) }
          end
        end
      end
    end
    
    tests_upload.state = 4
    tests_upload.save!
  end
  
  def collect_tests_in(zip, fname)
    dirs = {}
	  Zip::ZipFile.open(fname) do |zip|
	    zip.each do |entry|
	      next unless entry.file?
		    puts entry.name
        dir = (dirs[entry.parent_as_string] ||= DirInfo.new(entry.parent_as_string))
				case entry.name
				when %r!(?:^|/)(\d+)(\.in)?$!
				  dir.test($1.to_i).input = entry.name
				when %r!(?:^|/)(\d+)(\.out|\.ans|\.a)$!
				  dir.test($1.to_i).answer = entry.name
				when %r!(?:^|/)(\d+)(\.pts)$!
				  dir.test($1.to_i).pts = entry.name
				when %r!(?:^|/)checker.exe$!
				  dir.checker_file = entry.name
	      else
	        dir.leftover << entry.name
				end
      end
    end
    return dirs
  end

end
