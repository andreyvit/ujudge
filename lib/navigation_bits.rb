
module ContestAcceptor
protected
  def accept_contest
    @contest = Contest.find_by_short_name(@params[:contest_name])
    raise ActiveRecord::RecordNotFound if @contest.nil?
  end
end