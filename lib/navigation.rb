#
module Navigation
  
  module Controller
    def included(base)
      base.extend(ClassMethods)
      base.class_eval do
        before_filter :setup_navigation
      end
    end
    
    def setup_navigation
      classname = self.class.navigation_data
      klass = classname.to_s.split("::").inject(Object) { |par, const| par.const_get(const) }
      @nav = klass.new
    end
    
    module ClassMethods
      def navigation(id)
        self.navigation_data = id
      end
      
      def navigation_data=(o)
        write_inheritable_attribute('@navigation_data', o)
      end
      
      def navigation_data
        read_inheritable_attribute('@navigation_data')
      end
    end
  end
    
  module Base
    def included(base)
      base.extend(BaseClassMethods)
      base.class
    end
  end
  
  module BaseClassMethods
    def item
    end
  end
  
  class AbstractItem
    attr_accessor :subitems
    
    def initialize
      @subitems = []
    end
  end
  
  class Item
    attr_reader :link, :highlights
    attr_accessor :name, :title, :condition

    def initialize
      @highlights = []
      @condition = "true"
      yield self if block_given?
    end

    def link=(options)
      @link = options
      @highlights << options
    end

    # takes in input a Hash (usually params)
    def highlighted?(options={})
      result = false

      @highlights.each do |h| # for every highlight
        highlighted = true
        h.each_key do |key|   # for each key
          highlighted &= h[key].to_s==options[key].to_s   
        end 
        result |= highlighted
      end
      return result
    end
    
  end
end

class MyNav < Navigation::Base
  
end
