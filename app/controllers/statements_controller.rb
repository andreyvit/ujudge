class StatementsController < ApplicationController
  before_filter :set_problem
  before_filter :find_or_initialize_statement
  before_filter :set_tabs

  def index
    respond_to do |wants|
      wants.js  { 
        render :partial => 'show_statement_editor',
          :locals => {:statement => @statement, :problem => @problem}
      }
      wants.html {
        render :partial => 'statement_editor',
          :locals => {:statement => @statement, :problem => @problem}
      }
    end
  end
  
  def create
    unless params[:file].nil?
      #RAILS_DEFAULT_LOGGER.info((params[:file].methods - Object.new.methods).sort.join(", "))
      @statement.attributes = params[:statement]
      unless @statement.new_record?
        fname = File.join(RAILS_ROOT, "public/statements", @statement.cookie, @statement.filename)
        File.unlink(fname)
        fname = File.join(RAILS_ROOT, "public/statements", @statement.cookie)
        Dir.rmdir(fname)
      end
      @statement.filename = params[:file].original_filename 
      @statement.cookie = String.random_string(10) 
      @statement.save!
      fname = "public/statements/" + @statement.cookie + "/"+ @statement.filename
      f = "public/statements/"
      Dir.mkdir(f) unless File.exists?(f)
      f = "public/statements/" + @statement.cookie + "/"
      Dir.mkdir(f) unless File.exists?(f)
      File.open(fname, "wb") do |f|
        f.write(@params[:file].read())
      end
      redirect_to :back
    end
  rescue ActiveRecord::RecordInvalid
    render :partial => 'show_statement_editor', :locals => {:problem => @problem}
  end

  def destroy
    fname = File.join(RAILS_ROOT, "public/statements", @statement.cookie, @statement.filename)
    RAILS_DEFAULT_LOGGER.info ">>>>> #{fname}"
    File.unlink(fname)
    fname = File.join(RAILS_ROOT, "public/statements", @statement.cookie)
    Dir.rmdir(fname)
    @statement.destroy
    redirect_to :back
  rescue ActiveRecord::RecordInvalid
    render :partial => 'show_statement_editor', :locals => {:problem => @problem}
  end
  
private
  
  def find_or_initialize_statement
    @statement = if params[:id].blank?
      @problem.statements.find(:first, :order => 'id DESC') ||
        @problem.statements.build
    else
      @problem.statements.find(params[:id])
    end
  end

end
