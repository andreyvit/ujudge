
class ContestsController < ApplicationController
  helper :redbox
  before_filter :set_contest, :except => ['index', 'manage', 'create_training']
  before_filter :set_tabs
  layout 'control'
      
  def index
    if current_user.is_a?(User)
      redirect_to manage_contests_url
      return
    end
    @contests = Contest.find(:all, :conditions => {:publicly_visible => 1})
  end
      
  def manage
    @contests = Contest.find(:all)
    @server_status = Server.status
  end
  
  def show
    if current_user.is_a?(Team) && current_user.contest_id == @contest.id
      redirect_to team_participation_url(@contest, current_user)
    elsif current_user.allow?(:edit_contest)
      redirect_to edit_contest_url(@contest) 
    else
      # show
      @messages = @contest.messages.find(:all, :order => 'messages.created_at DESC') 
    end
  end
  
  def edit
  end
  
  def update
    @contest.attributes = params[:contest]
    @contest.state = params[:contest][:state] unless params[:contest][:state].nil?
    @contest.save!
    flash[:notice] = "Изменения сохранены"
    redirect_to :back
  end
  
  def create_training
    @contest = Contest.create
    redirect_to edit_contest_url(@contest)
  end
  
protected
  
	def set_contest
    @contest = Contest.find(params[:id])
	end

end



