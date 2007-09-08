class RunTest < ActiveRecord::Base
  belongs_to :run
  
  def display_outcome
    case self.outcome
    when nil
    else
      self.outcome
    end
  end
  
  def succeeded?
    self.outcome === 'ok'
  end
  
  def outcome_info
    TestOutcome.find_by_id(self.outcome)
  end

  def short_display_outcome
    if not self.partial_answer.nil?
      sprintf("%0.1f", self.partial_answer.to_f)
    elsif !self.points.nil? && (self.points.to_i > 0 || outcome == 'ok')
      self.points.to_i
    elsif not outcome.nil?
      outcome_info.short_display_name
    end
  end

  def normal_display_outcome
    if not self.partial_answer.nil?
      sprintf("%0.1f", self.partial_answer.to_f)
    elsif !self.points.nil? && (self.points.to_i > 0 || outcome == 'ok')
      self.points.to_i
    elsif not outcome.nil?
      outcome_info.display_name
    end
  end
end
