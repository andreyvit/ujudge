class FormsController < ApplicationController
  layout 'control'
  before_filter :set_current_tab
  before_filter :set_tabs

  def index
    list
    render :action => 'list'
  end

  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def index
    @forms = Form.find(:all)
  end

  def show
    redirect_to edit_form_url(params[:id])
  end

  def new
    @form = Form.new
  end

  def create
    @form = Form.new(params[:form])
    if @form.save
      flash[:notice] = 'Form was successfully created.'
      redirect_to :action => 'index'
    else
      render :action => 'new'
    end
  end

  def edit
    @form = Form.find(params[:id])
  end

  def update
    @form = Form.find(params[:id])
    if @form.update_attributes(params[:form])
      flash[:notice] = 'Form was successfully updated.'
      redirect_to forms_url
    else
      render :action => 'edit'
    end
  end

  def destroy
    Form.find(params[:id]).destroy
    redirect_to :action => 'index'
  end
  
private

  def set_current_tab
    @current_tab = :forms
  end
  
end
