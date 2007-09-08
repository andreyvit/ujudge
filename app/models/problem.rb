class Problem < CachedModel
  belongs_to :contest
  
  has_many :statements
  has_many :runs
  
  after_save :invalidate_cache
  after_destroy :invalidate_cache
  
  validates_presence_of :display_name
  
  def set_defaults!
    self.memory_limit = 64
    self.time_limit = 5000
    self.available = true
    self.display_name = "Задача #{contest.problems.count + 1}"
  end
  
  def self.collection_cache_key(contest)
    RAILS_DEFAULT_LOGGER.info "contest = #{contest}"
    "contest-#{contest.is_a?(Fixnum) ? contest : contest.id}-all_problems"
  end
  
  def invalidate_cache
    Cache.delete(self.class.collection_cache_key(contest_id))
  end
  
  def extra_name
    extras = []
    extras << self.name unless self.name.nil?
    extras << self.letter unless self.letter.nil?
    return self.display_name if extras.nil?
    return "#{self.display_name} (#{extras.join(", ")})"
  end
  
end
