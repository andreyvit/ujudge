class Contest < CachedModel
  
  attr_protected :state
  
  has_many :teams do
    def find_all
      Cache.get(Team.collection_cache_key(proxy_owner.id)) do
        self.find(:all)
      end
    end
  end
  
  has_many :problems do
    def find_all
      Cache.get(Problem.collection_cache_key(proxy_owner.id)) do
        self.find(:all, :order => 'letter ASC, display_name ASC')
      end
    end
  end
  
  has_many :rating_definitions
  
  has_many :questions
  
  has_many :messages
  
  has_many :recent_messages, :class_name => 'Message', :order => 'id DESC', :limit => 5
  
  #has_many :contests_forms
  has_and_belongs_to_many :forms
    
  has_many :submittions, :through => :teams
  has_many :runs, :through => :teams
  has_many :evaluated_runs, :through => :teams
  
  def to_param
    return "#{id}" if short_name.blank?
    "#{id}_#{short_name.to_url_friendly}"
  end
  
  def state=(new_state)
    new_state = new_state.to_i
    return if read_attribute('state') == new_state
    write_attribute('state', new_state)
    case new_state
    when 2
      self.started_at = Time.new
    end
  end
  
  def name
    display_name
  end
end
