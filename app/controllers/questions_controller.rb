
class QuestionsController < ApplicationController
	  
  before_filter :set_contest_and_maybe_team 
  before_filter :find_or_initialize_question
  before_filter :set_tabs
  before_filter :set_current_tab
  before_filter :check_access
  before_filter :check_write_access, :except => ['index', 'create']
  layout 'control'
  
  def index
  	find_all_questions
  	@problems = @contest.problems.find(:all)
    if can_answer_questions?
      render :action => 'index_j'
    else
      render :action => 'index_t'
    end
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
    case params[:answer]
    when "see_statement"         then @question.answer = "Читайте условие."
    when "no_comments"           then @question.answer = "Без комментариев."
    when "yes"                   then @question.answer = "Да."
    when "no"                    then @question.answer = "Нет."
    end
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
  
  def can_answer_questions?
    current_user.allow?(:answer_questions)
  end
  
  def check_access
    unless current_user.is_a?(Team) || current_user.is_a?(User)
      params[:message] = "Нужно войдите в систему"
      redirect_to contest_url(@contest)
      return false
    end
  end
  
  def check_write_access
    security_violation unless can_answer_questions?
  end
  
end
