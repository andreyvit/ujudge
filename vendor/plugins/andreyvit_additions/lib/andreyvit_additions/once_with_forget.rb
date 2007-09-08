class Object
  def self.once_with_forget *syms
    syms.each do |sym|
      module_eval <<-"end_eval"
        alias_method :__#{sym.to_i}__, :#{sym.to_s}
        private :__#{sym.to_i}__
        def #{sym.to_s}
          unless @__#{sym.to_i}_known__
            @__#{sym.to_i}__ = __#{sym.to_i}__
            @__#{sym.to_i}_known__ = true
          end
          @__#{sym.to_i}__ 
        end
        
        def forget_#{sym.to_s}
          @__#{sym.to_i}__ = nil
          @__#{sym.to_i}_known__ = false
        end
      end_eval
    end # syms.each
  end # self.once_with_forget
end
  
class ActiveRecord::Base
  def self.validates_condition(*attrs)
    options = attrs.last.is_a?(Hash) ? attrs.pop.symbolize_keys : {}
    attrs = attrs.flatten

    # Declare the validation.
    send(validation_method(options[:on] || :save)) do |record|
      yield record
    end
  end
end
