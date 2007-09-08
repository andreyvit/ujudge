class TestingQueueController < ApplicationController
  
  current_tab :testing
  before_filter :set_contest
  before_filter :set_tabs
  before_filter :find_all_runs
  
  def show
  end
  
private
  
  def find_all_runs
    @runs = @contest.runs.find(:all, :order => 'id DESC', :limit => 20)
  end
  
end