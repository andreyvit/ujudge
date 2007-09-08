class ActiveRecord::Base
  def self.find_random(options = {})
    options = options.dup
    options[:order] = 'RAND()'
    options[:limit] ||= 1
    self.find(:all, options)
  end
end
