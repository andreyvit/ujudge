class WorkingDirectory < Directory
  def initialize(path)
    super(path)
    
    unless File.directory?(@path)
      # begin
        Dir.mkdir(@path)
      # rescue SystemCallError => e
      # end
    end
  end
  
  def clean!(files_to_leave = [])
    files_to_leave = files_to_leave.collect {|f| self.path_of(f)}
    FileUtils.rmdir_children(@path, files_to_leave)
  end
end
