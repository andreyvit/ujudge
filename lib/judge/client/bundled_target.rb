class Judge::Client::BundledTarget
  attr_reader :path

  def initialize(path)
    @path = path
  end

  def exists?
    File.directory?(@path)
  end

  def create
    Dir.mkdir(@path)
  end

  def delete
    FileUtils.rmdir_r(@path)
  end

  def path_of(file)
    File.join(@path, file)
  end

end
