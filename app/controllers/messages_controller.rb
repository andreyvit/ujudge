class MessagesController < ApplicationController
  
  before_filter :set_contest
  before_filter :find_or_initialize_news
  before_filter :set_tabs
  layout 'control'
  
  def index
    find_all_messages
  end
  
  def new
  end

  def create
    @message.attributes = params[:message]
    @message.save!
    redirect_to :back
  rescue ActiveRecord::RecordInvalid
  end
  
  def destroy
    @message.destroy
    redirect_to :back
  end
  
  def update
    @news.save!
  rescue ActiveRecord::RecordInvalid
  end
  
  def edit
  end
  
private

  def find_all_messages
    @messages = @contest.messages.find(:all, :order => 'messages.created_at DESC')
  end
  
  def find_or_initialize_news
    @message = if params[:id].blank?
      @contest.messages.build
    else
      @contest.messages.find(params[:id])
    end
  end
  
end
