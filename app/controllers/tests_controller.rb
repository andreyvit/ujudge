class TestsController < ApplicationController
  
  before_filter :set_problem

  def index
#    @tests = Tests.find(:all)
    
    respond_to do |format|
      format.js  { 
        render :partial => 'show_tests_editor',
          :locals => {:problem => @problem}
      }
      format.html {
        render :partial => 'tests_editor',
          :locals => {:problem => @problem}
      }
    end
  end

  # GET /tests/1
  # GET /tests/1.xml
  def show
    @tests = Tests.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @tests.to_xml }
    end
  end

  # GET /tests/new
  def new
    @tests = Tests.new
  end

  # GET /tests/1;edit
  def edit
    @tests = Tests.find(params[:id])
  end

  # POST /tests
  # POST /tests.xml
  def create
    @tests = Tests.new(params[:tests])

    respond_to do |format|
      if @tests.save
        flash[:notice] = 'Tests was successfully created.'
        format.html { redirect_to tests_url(@tests) }
        format.xml  { head :created, :location => tests_url(@tests) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @tests.errors.to_xml }
      end
    end
  end

  # PUT /tests/1
  # PUT /tests/1.xml
  def update
    @tests = Tests.find(params[:id])

    respond_to do |format|
      if @tests.update_attributes(params[:tests])
        flash[:notice] = 'Tests was successfully updated.'
        format.html { redirect_to tests_url(@tests) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @tests.errors.to_xml }
      end
    end
  end

  # DELETE /tests/1
  # DELETE /tests/1.xml
  def destroy
    @tests = Tests.find(params[:id])
    @tests.destroy

    respond_to do |format|
      format.html { redirect_to tests_url }
      format.xml  { head :ok }
    end
  end
end
