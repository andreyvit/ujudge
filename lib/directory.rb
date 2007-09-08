
class Directory
  attr_reader :path
  
  def initialize(path)
    @path = path
  end
  
  def path_of(filename)
    File.expand_path(filename, @path)
  end
end
