
module DynamicForms
  class Form
    attr_accessor :intro
    attr_reader :groups
    
    def initialize
      @groups = []
    end
  end

  class Group
    attr_accessor :title
    attr_reader :groups
    
    def initialize
      @groups = []
    end
  end

  class Subgroup
    attr_accessor :help
    attr_reader :items
    
    def initialize
      @items = []
    end
  end
  
  class Item
    attr_accessor :caption
  end
  
  class TextItem < Item
    attr_accessor :caption
  end
end