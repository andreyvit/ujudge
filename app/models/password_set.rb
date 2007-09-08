class PasswordSet < ActiveRecord::Base
  
  belongs_to :principal, :polymorphic => true
  has_many :passwords
  
  def self.generate_new(size, options = {})
    ps = self.new(options)
    ps.save!
    size.times { ps.passwords << Password.generate_new }
    return ps
  end
  
end
