class FieldsController < ApplicationController
  
  layout 'control'
  before_filter :set_current_tab
  before_filter :set_tabs
  
  before_filter :set_form
  
  def index
    @fields = @form.fields.find(:all)
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def show
    redirect_to edit_field_url(@form, params[:id])
  end

  def new
    @field = @form.fields.build
  end

  def create
    @field = @form.fields.build
    @field.attributes = params[:field]
    if @field.save
      flash[:notice] = 'Field was successfully created.'
      redirect_to fields_url(@form)
    else
      render :action => 'new'
    end
  end

  def edit
    @field = Field.find(params[:id])
  end

  def update
    @field = Field.find(params[:id])
    if @field.update_attributes(params[:field])
      flash[:notice] = 'Field was successfully updated.'
      redirect_to fields_url(@form)
    else
      render :action => 'edit'
    end
  end

  def destroy
    Field.find(params[:id]).destroy
    redirect_to fields_url(@form)
  end
  
private

  def set_form
    @form = Form.find(params[:form_id])
  end

  def set_current_tab
    @current_tab = :forms
  end

end
