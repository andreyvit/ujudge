class TestsUploadsController < ApplicationController
  before_filter :set_problem
  before_filter :set_tabs
  
  def show
    @tests_upload = TestsUpload.find(params[:id])

    if @tests_upload.state == 2 || @tests_upload.state == 4
      result = YAML.load(@tests_upload.message)
      @errors = result.errors
      @warnings = result.warnings
      @mappings = []
      result.problem_id_to_tests_directory.each do |dir_name, problem_id|
        @mappings << OpenStruct.new(:problem => Problem.find(problem_id), :dir_name => dir_name)
      end
    end
    
    case @tests_upload.state
    when 1
      render :action => 'show_prewait'
    when 2
      if @errors.empty?
        render :action => 'show_pre_ok'
      else
        render :action => "show_pre_errors"
      end
    when 3
      render :action => 'show_prewait'
    when 4
      render :action => 'show_done'
    end

    # respond_to do |format|
    #   format.html # show.rhtml
    #   format.xml { render :xml => @tests_upload.to_xml }
    # end
  end

  def create
    unless Server.ok?
      render_text "Невозможно выполнить закачку, пока не запущен сервер."
      return
    end
    
    if params[:file].nil?
      render_text "Требуется указать файл."
      return
    end
    
    data = @params[:file].read
    if data.empty?
      render_text "Требуется указать файл."
		  return
		end
    
    @tests_upload = TestsUpload.new(params[:tests_upload])
    @tests_upload.contest_id = @contest.id
    @tests_upload.problem_id = @problem.id
    @tests_upload.original_filename = params[:file].original_filename
	  @tests_upload.filename = nil
    @tests_upload.state = 0
	  @tests_upload.save!
    @tests_upload.filename = File.join("tmp/tests_upload/", "%05d.zip" % @tests_upload.id)
	  File.makedirs(File.dirname(@tests_upload.filename))
	  File.open(@tests_upload.filename, "wb") do |f|
	    f.write(data)
	  end
    @tests_upload.state = 1
	  @tests_upload.save!
    
    Server.start_processing_tests_upload(@tests_upload.id)
    
	  redirect_to tests_upload_url(@problem.contest, @problem, @tests_upload)
  rescue ActiveRecord::RecordInvalid
    render :partial => 'show_statement_editor', :locals => {:problem => @problem}
  end
  
  def accept
    @tests_upload = TestsUpload.find(params[:id])
    @tests_upload.state = 3
	  @tests_upload.save!
    Server.start_processing_tests_upload(@tests_upload.id)
	  redirect_to tests_upload_url(@problem.contest, @problem, @tests_upload)
  end

end
