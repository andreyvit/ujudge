
class PerMemberInstance
  
  class Errors
    attr_reader :errors
    
    def initialize
      @errors = {}
    end
    
    def on(id)
      return @errors[id.to_s]
    end
    
    def add(id, message)
      @errors[id.to_s] = message
    end
  end
  
  def initialize(member, fields)
    @member = member
    @fields = fields
    @attributes = {}
    @attr_set = Set.new
    @errors = Errors.new
  end
  
  def attributes=(hash)
    hash.each { |k,v| 
      if k =~ /\(1i\)$/
        k = $`
        vals = [v]
        kk = "#{k}(#{vals.size+1}i)"
        while !hash[kk].nil?
          vals << hash[kk]
          kk = "#{k}(#{vals.size+1}i)"
        end
        vals = vals.collect { |v| v.to_i }
        self[:"#{k}"] = Date.new(*vals)
      else
        self[:"#{k}"] = v
      end
    }
  end
  
  def errors
    @errors
  end
  
  def []=(id, value)
    @attributes[id] = value
    @attr_set << id
  end
  
  def [](id)
    @attributes[id]
  end
  
  def method_missing(id, *args)
    return @attributes[id] if @attr_set.include?(id)
    super
  end
  
  def valid?
    @errors = Errors.new
    result = true
    @fields.each do |field|
      v = PerMemberValue.new
      v.member = @member
      v.field = field
      v.value = self[:"#{field.name}"]
      result = v.valid_data?(errors) && result
    end
    result
  end
  
  def save!
    @fields.each do |field|
      value = PerMemberValue.find_by_member_id_and_field_id(@member, field)
      if value.nil?
        value = PerMemberValue.new
        value.member = @member
        value.field = field
      end
      value.value = self[:"#{field.name}"].to_s
      value.save!
    end
  end
  
end