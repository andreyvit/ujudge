require_dependency 'dynamic_fields'

class Team < CachedModel
  include DynamicFields::Model
  include LoginSystem::Principal

  belongs_to :contest
  belongs_to :university
  
  has_many :cookies, :as => :owner
  has_many :members
  has_many :password_sets, :as => :principal
  has_many :submittions
  has_many :runs #, :through => :submittion
  has_many :evaluated_runs, :class_name => 'Run', :conditions => ['runs.state IN (3,4)'], :include => [:tests]
  
  after_save :invalidate_cache
  after_destroy :invalidate_cache
      
  def display_name
    name
  end
  
  def create_passwords!(reason)
    PasswordSet.generate_new(4, :principal => self, :used => false, :reason => reason)
  end
  
  def allow?(perm)
    return true if perm == :submit
    false
  end
  
  validates_presence_of :name, :message => :required_field_n.s
  validates_length_of :name, :minimum => 4
  
  validates_presence_of :email, :message => :required_field_f.s
  validates_email :email
  
  validates_presence_of :coach_names, :message => :required_field_pl.s
  
  validates_email :coach_email, :message => :required_field_f.s
  
  validates_selected_index :university_id
  validates_each :university_id do |record, attr, value|
    record.errors.add attr, "Нужно сделать выбор" if value.nil? || value == -1
  end
  
  def new_university?
    university_id.nil? || 0 == university_id
  end
  
  def member_names
    members.sort {|a,b| a.last_name <=> b.last_name}.
      collect { |m| "#{m.first_name} #{m.last_name}"}.join(", ")
  end
  
  def active_password_set
    password_sets.find(:first, :order => 'id desc')
  end
  
  # please note that this does self.save!
  def send_password!(reason)
    # create a password if it does not exist
    create_passwords!(reason) if password_sets.empty?
    ps = active_password_set
    raise "internal error: could not create a password for team #{self.id} (#{self.name})" if ps.nil?
    result = OpenStruct.new
    result.password_set = ps
    begin
      Mails.deliver_team_registration_confirmation(self, ps)
    rescue Exception => e
      RAILS_DEFAULT_LOGGER.warn "cannot send email to team #{self.id} (#{self.name}), email #{self.email}: error #{e.class.name} -- #{e}"
      result.success = false
      result.exception = e
    else
      self.password_sent_at = Time.now
      self.save!
      result.success = true
    end
    return result
  end
  
  def passwords_text
    ps = active_password_set
    return '' if ps.nil?
    ps.passwords.find(:all).collect {|p| p.text}.join ", "
  end
  
  def self.listing_info
    {
      :caption => "Команда",
      :columns => [
        {:method => :id, :caption => "Номер", :show => true},
        {:method => :name, :caption => "Название", :show => true},
        {:method => :email, :caption => "Электронная почта", :priv => :view_emails, :show => true},
        {:method => :passwords_text, :caption => "Пароли", :priv => :view_emails, :show => false},
        {:method => :member_names, :caption => "Имена членов"},
        {:method => :coach_names, :caption => "Имена тренеров"},
        {:method => :coach_email, :caption => "Электронная почта тренера", :priv => :view_emails},
      ],
      :associations => [
        {:name => :university},
      ]
    }
  end

  def self.collection_cache_key(contest)
    "contest-#{contest.respond_to?(:id) ? contest.id : contest}-all_teams"
  end
  
  def invalidate_cache
    Cache.delete(self.class.collection_cache_key(contest_id))
  end
  
  def identifying_name
    if name.empty? then "\##{id}" else name end
  end
  
end
