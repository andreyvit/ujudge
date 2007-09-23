require 'digest/sha1'
require_dependency 'login_system'

class User < CachedModel
  
  # include LoginSystem::Principal

  has_many :password_sets, :as => :principal
  
  def active_password_set
    password_sets.find(:first, :order => 'id desc')
  end
 
  def create_passwords!(reason)
    PasswordSet.generate_new(4, :principal => self, :used => false, :reason => reason)
  end
  
  def display_name
    full_name
  end

  def full_name
    "#{first_name} #{middle_name} #{last_name}" +
      if position.nil? || position.empty? then "" else ", #{position}" end
  end
  
  def allow?(perm)
    return true if last_name == 'Таранцов'
    return true if perm == :submit
    return true
  end
  
  # Possible values for +reason+ are: :initial, :change, :forgot
  def create_password!(reason)
    
  end
  
  def passwords_text
    ps = active_password_set
    return '' if ps.nil?
    ps.passwords.find(:all).collect {|p| p.text}.join ", "
  end

#  def self.authenticate(login, pass)
#    find_first(["login = ? AND password = ?", login, sha1(pass)])
#  end  
#
#  def change_password(pass)
#    update_attribute "password", self.class.sha1(pass)
#  end
#    
#  protected
#
#  def self.sha1(pass)
#    Digest::SHA1.hexdigest("novosibirsk-judging-system--#{pass}--")
#  end
    
#  before_create :crypt_password
  
#  def crypt_password
#    write_attribute("password", self.class.sha1(password))
#  end

#  validates_length_of :login, :within => 3..40
#  validates_length_of :password, :within => 5..40
#  validates_presence_of :login, :password, :password_confirmation
#  validates_uniqueness_of :login, :on => :create
#  validates_confirmation_of :password, :on => :create     
end
