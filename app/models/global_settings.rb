
class GlobalSettings
  attr_accessor :bgcolor, :sidebar_color, :top_line_color, :top_text_color, :server_name, :dark_tab_color, :light_tab_color
  
  @@instance = nil
  
  def self.instance
    @@instance ||= self.load
  end
  
  def self.save!
    File.open(self.filename, 'w') { |f| f.write YAML.dump(self.instance) }
  end
  
private
    
	def self.load
	  File.open(self.filename, 'r') { |f| YAML.load(f.read) }
  rescue
    GlobalSettings.new
	end
    
	def self.filename
	  File.join(RAILS_ROOT, 'data', 'config.yml')
	end
    
end
