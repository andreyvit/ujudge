require_dependency "login_system"
require_dependency 'navigation_bits'
require_dependency 'listing'

class ApplicationController < ActionController::Base
  include LoginSystem 
  
  helper_method :current_user
  helper_method :logged_in?
  
  layout 'control'
  
protected
  def render_reload_js
    render :text => "window.location.href = window.location.href;"
  end
  
  def security_violation
    render :partial => 'errors/security_violation', :status => 403, :layout => 'application'
  end
  
  def access_denied
    render :partial => 'errors/security_violation', :status => 403, :layout => 'application'
  end
  
  def rescue_action(exception)
    exception.is_a?(ActiveRecord::RecordInvalid) ? render_invalid_record(exception.record) : super
  end

  def render_invalid_record(record)
    render :action => (record.new_record? ? 'new' : 'edit')
  end

  def set_contest
    @contest = Contest.find(params[:contest_id])
    true
  end
  
	def set_problem
	  set_contest
	  @problem = Problem.find(params[:problem_id])
    true
	end
    
	def set_team
	  set_contest
	  @team = Team.find(params[:team_id], :order => 'id DESC')
	end
  
   def set_team_submittion
    set_team
    @run = @team.runs.find(params[:submittion_id])
  end
  
  def verify_team_access
    if current_user.is_a?(Team)
      unless @team.id == current_user.id
        access_denied
        return false
      end
    elsif !current_user.allow?(:access_team_data)
      access_denied
      return false
    end
  end
  
  def set_manager_tabs
  	@page_heading = (@contest.display_name || "Контест #{@contest.id}")
	  @page_tabs = []
	  @page_tabs << Tab.new(:dashboard, 'Олимпиада', lambda { edit_contest_url(@contest) })
	  # @page_tabs << Tab.new(:tours, 'Туры')
	  # @page_tabs << Tab.new(:schedule, 'Расписание')
	  @page_tabs << Tab.new(:news, 'Новости', lambda { messages_url(@contest) })
	  @page_tabs << Tab.new(:problems, 'Задачи', lambda { problems_url(@contest) })
	  @page_tabs << Tab.new(:teams, 'Участники', lambda { overview_teams_url(@contest) })
	  @page_tabs << Tab.new(:rating, 'Рейтинг', lambda { contest_rating_url(@contest, 'default') })
	  @page_tabs << Tab.new(:testing, 'Тестирование', lambda { contest_queue_url(@contest) })
	  @page_tabs << Tab.new(:questions, 'Вопросы', lambda { contest_questions_url(@contest) })


    @page_links = []
    case @current_tab
    when :testing
      @page_links << PageLink.new(:queue, 'Очередь тестирования',lambda { contest_queue_url(@contest) })
      @page_links << PageLink.new(:retesting, 'Перетестирование',lambda { contest_retesting_url(@contest) })
    end
      
	  # @page_tabs << Tab.new(:testing, 'Тестирование')
	  # @page_tabs << Tab.new(:communication, 'Общение')
  end

  def self.current_tab(tab)
    before_filter :set_current_tab
    
    define_method(:set_current_tab) do
      @current_tab = tab
    end
  end
    
  def set_arena_tabs
  	@page_heading = (@contest.display_name || "Контест #{@contest.id}")
    @page_tabs = []
    @page_tabs << Tab.new(:news, 'Новости', lambda { contest_url(@contest) })
    @page_tabs << Tab.new(:submittions, 'Сдать', lambda { team_submittions_url(@contest, @team) }) if @contest.state == 2
    @page_tabs << Tab.new(:rating, 'Рейтинг', lambda { team_rating_url(@contest, @team, 'default') })
    @page_tabs << Tab.new(:questions, 'Вопросы', lambda { team_questions_url(@contest, @team) })
  end
  
  def set_spectator_tabs
  	@page_heading = (@contest.display_name || "Контест #{@contest.id}")
    @page_tabs = []
    @page_tabs << Tab.new(:contest, 'Олимпиада', lambda { contest_url(@contest) })
    @page_tabs << Tab.new(:teams, 'Команды', lambda { overview_teams_url(@contest) }) if @contest.registration_open > 0
    @page_tabs << Tab.new(:rating, 'Рейтинг', lambda { contest_rating_url(@contest, 'default') })
  end
  
  def set_general_tabs
    @page_tabs = []
    @page_tabs << Tab.new(:contests, 'Олимпиады', lambda { contests_url })
    @page_tabs << Tab.new(:appearance, 'Настройки', lambda { appearance_url })
    @page_links = []
    case @current_tab
    when :appearance
      @page_links << PageLink.new(:texts, 'Тексты',lambda { texts_url() })
      @page_links << PageLink.new(:appearance, 'Внешний вид',lambda { appearance_url() })
    end
  end
  
  def set_contest_tabs
    if current_user.is_a?(User)
      set_manager_tabs
    elsif current_user.is_a?(Team)
      set_arena_tabs
    else
      set_spectator_tabs
    end
  end
  
  def set_tabs
    if @contest.nil?
      set_general_tabs
    else
      set_contest_tabs
    end
  end
  
end
