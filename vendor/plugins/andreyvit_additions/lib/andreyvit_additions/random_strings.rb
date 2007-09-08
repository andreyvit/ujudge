
class String
  def self.random_string(len)
  	s = "".dup
  	len.times do 
  		s << (?A + rand(26));
  	end
  	s		
  end
  
  def self.random_hex_string(len, base = 16)
    s = "".dup
    len.times do 
      s << rand(16).to_s(base);
    end
    s.upcase
  end

end