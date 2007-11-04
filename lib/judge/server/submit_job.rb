
class Judge::Server::SubmitJob < Judge::Server::Job
  
  def initialize(server, team_id, problem_id, compiler_id, text)
    @server      = server
    @team_id     = team_id
    @problem_id  = problem_id
    @compiler_id = compiler_id
    @text        = text
  end

  def run
    puts "submitting... #{@team_id} / #{@problem_id} / #{@compiler_id}"
    @team = Team.find(@team_id, :include => [:contest])
    @contest = @team.contest
    
    @submittion = Submittion.new
    @submittion.team_id = @team_id
    @submittion.compiler_id = @compiler_id 
    @submittion.problem_id = @problem_id
    @submittion.text = @text
    @submittion.state = 0
    @submittion.save!
    
	  @submittion.file_name = "#{@contest.short_name}-team#{@submittion.team_id}-#{@submittion.problem.name}-submittion#{@submittion.id}.#{@submittion.compiler.extension}"
    @submittion.save!
    
	  f = File.join(UJUDGE_ROOT, 'data')
    Dir.mkdir(f) unless File.exists?(f)
	  f = File.join(UJUDGE_ROOT, 'data', @contest.short_name)
    Dir.mkdir(f) unless File.exists?(f)
	  f = File.join(UJUDGE_ROOT, 'data', @contest.short_name, 'solutions')
    Dir.mkdir(f) unless File.exists?(f)
	  f = File.join(UJUDGE_ROOT, 'data', @contest.short_name, 'solutions', @submittion.file_name)
    
    File.open(f, 'wb') do |f|
	    f.write(@submittion.text)
    end
	  
	  run = @submittion.runs.build(:problem_id => @submittion.problem_id, :compiler_id => @submittion.compiler_id, :team_id => @submittion.team_id)
	  run.submitted_at = Time.now
    run.penalty_time = ((run.submitted_at - contest_started_at) / 60).to_i
	  run.state = 0
	  run.state_assigned_at = Time.now
    run.file_name = @submittion.file_name
	  run.save!

    puts "SUBMITTION #{@submittion.id}, RUN #{run.id}"
  end
  
  def contest_started_at
    (@team && @team.started_at_override) || @contest.started_at
  end
  
end
