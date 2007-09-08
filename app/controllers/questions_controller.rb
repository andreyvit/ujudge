
class QuestionsController < ApplicationController
	  
  before_filter :set_contest_and_maybe_team 
	  before_filter :find_or_initialize_question
	  before_filter :set_tabs
	  before_filter :set_current_tab
	  layout 'control'
	  
	  def index
		find_all_questions
    if current_user.is_a?(Team)
      render :action => 'index_t'
    else
      render :action => 'index_j'
	  end
	  end
    
    def index_j
    end
    
    def index_p
    end
	  
	  def new
	  end
	
	  def create
		@question.attributes = params[:question]
		@question.asked_at = Time.new
    @question.team_id = @team.id
		@question.save!
		redirect_to :back
	  rescue ActiveRecord::RecordInvalid
	  end
	  
	  def destroy
		@question.destroy
		redirect_to :back
	  end
	  
	  def update
	  	@question.visible_for_all_teams =  @question.visible_for_spectators = true unless params[:publish].nil?
        @question.attributes = params[:question]
		@question.answered_at = Time.new if @question.answered_at.nil?
		@question.save!
		redirect_to contest_questions_url(@contest)
	  rescue ActiveRecord::RecordInvalid
	  end
	  
	  def predefinedanswer
	  	
	  	@question.answer = "Без комментариев." if params[:answer] == "no_comments"
		  @question.answer = "Да." if params[:answer] == "yes"
		  @question.answer = "Нет." if params[:answer] == "no"
		  @question.answered_at = Time.new if @question.answered_at.nil?
		  @question.save!
		  redirect_to contest_questions_url(@contest)
    rescue ActiveRecord::RecordInvalid
	  end
	  
	  def publish
	  	@question.visible_for_all_teams = true
		@question.visible_for_spectators = true
		@question.save!
		redirect_to :back
	  rescue ActiveRecord::RecordInvalid
	  end
	  
	  def unpublish
	    @question.visible_for_all_teams = false
		@question.visible_for_spectators = false
		@question.save!
		redirect_to :back
	  rescue ActiveRecord::RecordInvalid
  	end
	  
	  def edit
	  end
	  
	private
	
	  def find_all_questions
	    if current_user.is_a?(User)
		    @questions = @contest.questions.find(:all,
		      :order => 'questions.asked_at DESC')
	    else
		    @questions = @contest.questions.find(:all,
		      :conditions => ['questions.team_id = ? OR questions.team_id IS NULL OR questions.visible_for_all_teams = 1', @team.id],
		      :order => 'questions.asked_at DESC')
	    end
	  end
	  
	  def find_or_initialize_question
		@question = if params[:id].blank?
		  @contest.questions.build
		else
		  @contest.questions.find(params[:id])
		end
	  end
	
	  def set_current_tab
	  	@current_tab = :questions
	  end
    
    def set_contest_and_maybe_team
      if current_user.is_a?(Team)
        set_team
      else
        set_contest
      end
    end
end
