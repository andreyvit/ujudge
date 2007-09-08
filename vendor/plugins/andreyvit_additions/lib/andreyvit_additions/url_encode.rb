
class String
  def urlencode
    gsub( /[^a-zA-Z0-9\-_\.!~*'()]/n ) {|x| sprintf('%%%02x', x[0]) }
  end
end

class Hash
  def urlencode
    (collect {|k,v| "#{k.to_s.urlencode}=#{v.to_s.urlencode}"}).join('&')
  end
end 
