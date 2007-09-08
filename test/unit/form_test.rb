require File.dirname(__FILE__) + '/../test_helper'

class FormTest < Test::Unit::TestCase
  def stub_form(form)
    class << form
      @@fields = [FormField.new(:first_name, :string), FormField.new(:last_name, :string)]
      @@fields.each { |f| f.required = true }
      def fields
        @@fields
      end
    end
    form
  end
  
  def stub_errors(errors)
    class << errors
      
      def by_attribute; @errors; end
      
    end
    errors
  end
  
  def stub_record(record)
    class << record
      
      def errors
        @errors ||= stub_errors(ActiveRecord::Errors.new)
      end
      
    end
    record
  end
  
  def stub_dynamic_record(record)
    class << record
      
      attr_accessor :first_name
      
      def attributes_storage
        @attributes_storage ||= {}
      end
      
      def read_attribute(id)
        return self.send(id) if respond_to?(id)
        attributes_storage[id]
      end
      
      def write_attribute(id, value)
        return send.send("#{id}=", value) if respond_to?("#{id}=")
        attributes_storage[id] = value
      end
      
      def method_missing(meth, *args, &block)
        return read_attribute(meth) if attributes_storage[meth]
        if meth.to_s =~ /^(.*)=/
          return write_attribute($1.intern, *args)
        end
      end
      
      def errors
        @errors ||= stub_errors(ActiveRecord::Errors.new)
      end
      
    end
    record
  end
  
  def test_invalid_because_of_required_field
    form = stub_form(Form.new)
    record = stub_record(OpenStruct.new)
    record.first_name = 'Andrey'
    assert(!form.valid?(record), "Form must be invalid")
    assert_equal(1, record.errors.size)
    assert_equal(Set.new([:first_name]), Set.new(record.errors.by_attribute.keys))
  end
  
  def test_valid
    form = stub_form(Form.new)
    record = stub_record(OpenStruct.new)
    record.first_name = 'Andrey'
    record.last_name = 'Tarantsov'
    assert(form.valid?(record), "Form must be valid")
  end
  
  def test_dynamic_fields
    form = stub_form(Form.new)
    record = stub_dynamic_record(Object.new)
    record.first_name = 'Andrey'
    record.last_name = 'Tarantsov'
    assert_equal(Set.new([:last_name]), Set.new(record.attributes_storage.keys))
    assert(form.valid?(record), "Form must be valid even when data is kept in dynamic fields")
  end
end
