
class Password < ActiveRecord::Base
  
  belongs_to :password_set
  
  NWORDS = 4
  NCHARS = 3
  
  
  def self.generate_new(options = {})
    
    # find already existing passwords that are close enough;
    # the current method is to load the entire DB — not very graceful!
    all_passwords = Password.find(:all, :select => 'text').collect { |p| p.text }

    guess = nil # declare variable :)
    loop do
      guess = String.random_string(8)
      break unless all_passwords.any? { |p| String.desimilarity(p, guess) < 2 }
    end
    
    return self.new({:text => guess}.update(options))
    
    # TODO: determine theoretical number of passwords and explore attack possibilities before enabling this
    
    words = Word.find_random(:limit => NWORDS)
    raise "Internal error while finding random words" unless words.size == NWORDS
    
    puts words.collect {|w| w.id}
    
    p = self.new
    NWORDS.times { |index| p.send("w#{index+1}=", words[index].id) }
    p.text = words.collect { |w| w.text[0..NCHARS] }.join("")
    
    return p
  end
  
  def self.authenticate(pwd)
    r = self.find_by_text(pwd)
    if r.nil?
      t = pwd.transtype(:en, :ru)
      r = self.find_by_text(t)
    end
    r
  end
  
  def self.find_by_text(text)
    logger.info "!!!!! #{text}"
    # XXX fix for Rails 2.0 (not sure it's correct)
    # self.find(:first, :conditions => ['text = ?', text, :include => [:password_set]])
    self.find(:first, :conditions => ['text = ?', text])
  end
  
  def words
    ids = [w1, w2, w3, w4]
    Word.find(ids)
  end
end
