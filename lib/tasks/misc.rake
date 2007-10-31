
namespace :ujudge do 
  task :restore_submittion_file_names => :environment do
    contest_id = ENV['CONTEST_ID']
    contest = Contest.find(contest_id)
    puts "Processing #{contest.short_name}..."
    teams = contest.teams.find(:all)
    errors = []
    teams.each_with_index do |team, team_counter|
      puts "(#{team_counter+1}/#{teams.size}) #{team.name}, id #{team.id}"
      submittions = team.submittions.find(:all)
      puts "- #{submittions.size} submittions."
      submittions.each do |submittion|
        if submittion.file_name.nil?
          run = submittion.runs.find(:first, :order => 'id')
          if run.nil?
            errors << "No file name for submittion #{submittion.id}"
          else
            submittion.file_name = run.file_name
            puts "- submittion #{submittion.id}, file name #{submittion.file_name}"
            submittion.save!
          end
        end
      end
    end
    if errors.empty?
      puts "Success."
    else
      puts "Done. Errors:"
      errors.each { |e| puts e }
    end
  end
  
  task :eliminate_repeated_submits => :environment do
    contest_id = ENV['CONTEST_ID']
    contest = Contest.find(contest_id)
    puts "Processing #{contest.short_name}..."
    teams = contest.teams.find(:all)
    errors = []
    candidates = []
    teams.each_with_index do |team, team_counter|
      puts "(#{team_counter+1}/#{teams.size}) #{team.name}, id #{team.id}"
      submittions = team.submittions.find(:all)
      puts "- #{submittions.size} submittions."
      prev_submittions = {}
      submittions.each do |submittion|
        prev_sub = prev_submittions[submittion.problem_id]
        catch(:dont_save) do
          catch(:done) do
            throw(:done) if prev_sub.nil?
            throw(:done) if prev_sub.compiler_id != submittion.compiler_id
            this_file = File.join(UJUDGE_ROOT, 'data', contest.short_name, 'solutions', submittion.file_name)
            prev_file = File.join(UJUDGE_ROOT, 'data', contest.short_name, 'solutions', prev_sub.file_name)
            throw(:done) if File.size(this_file) != File.size(prev_file)
            this_text = File.open(this_file) { |f| f.read }
            prev_text = File.open(prev_file) { |f| f.read }
            throw(:done) if this_text.strip != prev_text.strip
            
            candidates << submittion
            throw(:dont_save)
          end
          prev_submittions[submittion.problem_id] = submittion
        end
      end
    end
    candidates.each do |submittion|
      submittion.runs.each { |r| r.destroy }
      submittion.destroy
    end
    puts "#{candidates.size} submittions deleted."
    if errors.empty?
      puts "Success."
    else
      puts "Done. Errors:"
      errors.each { |e| puts e }
    end
  end
  
end