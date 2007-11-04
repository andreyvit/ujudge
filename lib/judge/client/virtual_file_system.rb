
class Judge::Client::VirtualFileSystem
  def initialize(path, server)
    @path = path
    @server = server
    File.makedirs(@path) unless File.directory?(@path)
  end
  
  def try_to_get(rel_path)
    puts "getting #{rel_path}"
    local_file = File.join(@path, rel_path)
    local_dir = File.dirname(local_file)
    File.makedirs(local_dir) unless File.directory?(local_dir)
    
    local_mtime = if File.exists?(local_file)
      File.mtime(local_file)
    else
      nil
    end
    
    result = @server.get_file(rel_path, local_mtime)

    case result
    when :unchanged
      return local_file
    when :not_found
      File.unlink(local_file) if File.exists?(local_file)
      return nil
    when Array
      remote_body, remote_mtime = *result
      puts "size: #{remote_body.size} bytes"
      File.open(local_file, 'wb') { |f| f.write(remote_body) }
      puts "real size: #{File.size(local_file)} bytes"
      File.utime(Time.new, remote_mtime, local_file)
      return local_file
    end
  end
  
  def get(rel_path)
    try_to_get(rel_path) or raise "File not found on the server: #{rel_path}"
  end
end
