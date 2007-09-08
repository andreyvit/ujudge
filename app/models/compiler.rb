class Compiler < ActiveRecord::Base
  
  def self.find_all
    Cache.get('all-compilers') do
      self.find(:all) 
    end
  end
  
end
