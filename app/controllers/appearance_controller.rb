
class AppearanceController < ApplicationController
  
  current_tab :appearance
  before_filter :set_tabs
  
  def show
    @settings = GlobalSettings.instance
  end
  
  def update
    gs = GlobalSettings.instance
    gs.top_line_color = @params[:color_scheme][:top_line]
    gs.top_text_color = @params[:color_scheme][:top_text]
    gs.bgcolor = @params[:color_scheme][:bgcolor]
    gs.sidebar_color = @params[:color_scheme][:rightcolor]
    gs.dark_tab_color = @params[:color_scheme][:dark_tab_color]
    gs.light_tab_color = @params[:color_scheme][:light_tab_color]
    GlobalSettings.save!
    redirect_to :back
  end
  
end
