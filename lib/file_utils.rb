
module FileUtils
  
  def self.rmdir_r(path, files_to_leave = [])
    rmdir_children(path, files_to_leave)
    Dir.rmdir(path) if files_to_leave.empty?
  end
  
  def self.rmdir_children(path, files_to_leave)
    Dir.foreach(path) do |file|
      next if ['.', '..'].include?(file)
      full_file = File.expand_path(File.join(path, file))
      if File.directory?(full_file)
        self.rmdir_children(full_file, files_to_leave)
        Dir.delete(full_file)
      else
        next if files_to_leave.include?(full_file)
        10.times do
          File.delete(full_file) rescue nil
          break if !File.file?(full_file)
          sleep 0.2
        end
      end
    end
  end
  
end


