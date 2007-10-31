
class GlobalConfig
  
  attr_reader :memcached_url
  attr_reader :server_url
  
  cattr_accessor :cache_config
  cache_config = false
  
  def initialize(data)
    @memcached_url = data['memcached']
    @server_url = data['server']
  end
  
  def self.instance
    if self.cache_config
      @@instance ||= self.load
    else
      self.load
    end
  end
  
private

  def self.load
    self.new(YAML.load(File.open(self.filename) { |f| f.read }))
  end
  
  def self.filename
    File.join(UJUDGE_ROOT, 'config', 'site.yml')
  end
  
end