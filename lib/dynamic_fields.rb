
module DynamicFields

  module Model
    def self.included(base)
      base.extend(ClassMethods)
    end
    
    def get_dynamic_value(field_id)
      Values.find_by_field_id_and_instance_id(field_id, self.id)
    end
    
    def set_dynamic_value(field_id, value)
      v = Values.find_by_field_id_and_instance_id(field_id, self.id)
      v = Values.new(:field_id => field_id, :instance_id => self.id) if v.nil?
      v.value = value.to_s
      v.save!
    end
    
    module ClassMethods
      def entity_short_name
        @entity_short_name ||= self.class_name.underscore.intern
      end

      def entity_short_name=(id)
        @entity_short_name = id
      end
    
      def entity
        @entity ||= Entity.find_by_short_name(self.sentity_short_name)
      end
      
      def dynamic_fields
        @dynamic_fields ||= self.entity.all_fields
      end
      
      def reset_dynamic_fields!
        @dynamic_fields = nil
      end
   end
  end

end