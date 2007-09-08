module TeamRatingsHelper
  def acm_designator(solution_state)
    if solution_state.nil?
      "&mdash;"
    elsif solution_state.succeeded?
      if solution_state.attemps > 1
        "+#{solution_state.attemps - 1}"
      else
        "+"
      end
    else
      "-#{solution_state.attemps}"
    end
  end
end
