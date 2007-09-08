class RatingsController < ApplicationController
  include ContestAcceptor

  def show
    accept_contest
    @ratingdef = RatingDefinition.find(params[:id], :include => [:ratings])
    
    case @ratingdef.scope_type
    when 'problem'
      render :action => 'problems_rating'
    when 'contest'
      @rating = @ratingdef.ratings.first
      render :action => 'contest_rating'
    end
  end
  
  def recalc
    accept_contest
    @ratingdef = RatingDefinition.find(params[:id])
    @ratingdef.recalculate!
    flash[:message] = 'Рейтинг пересчитан'
    redirect_to :action => 'show', :id => @ratingdef
  end
end
