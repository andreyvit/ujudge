
class Judge::Server::SetPointsJob < Judge::Server::Job
  def initialize(server, run)
    @server = server
    @run    = run
  end

  def run
    # calculate points for this run in points mode
    # TODO: calculate run state in ACM mode
    @server.clients.synchronize do
      @sol = Judge::Solution.new(@run)
      @problem = @sol.problem

      if @problem.tests.any? {|t| not t.points.nil?}
        points = nil # will be nil unless any passed test has assigned some points to us
        @run.tests.each do |run_test|
          prob_test = @problem.tests.find {|t| t.ord == run_test.test_ord }
          if prob_test.nil?
            puts "VERY VERY BAD"
            puts({'@problem.tests' => @problem.tests, 'run_test' => run_test}.to_yaml)
            return
          end
          unless prob_test.points.nil?
            points ||= 0
            if run_test.outcome == 'ok'
              pts_for_test = prob_test.points.to_i 
            else
              pts_for_test = 0
            end
            run_test.points = pts_for_test
            run_test.save!
            points += pts_for_test
          end
        end

        @run.points = points
      end

      @run.state = 4
      @run.state_assigned_at = Time.now
      @run.save!
    end

    puts "DONE WITH RUN #{@run.id}"
  end
end
