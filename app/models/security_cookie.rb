class SecurityCookie < ActiveRecord::Base
  belongs_to :owner, :polymorphic => true
  set_table_name 'cookies'

  def self.generate_new(options = {})
    guess = String.random_string(12)
    return self.new({:text => guess}.update(options))
  end
  
  def self.find_by_owner_and_usage_and_text(owner, usage, text)
    self.find(:first, :conditions => ['owner_type = ? and owner_id = ? and cookies.usage = ? and cookies.text = ?',
      owner.class.name, owner.id, usage, text])
  end
end
