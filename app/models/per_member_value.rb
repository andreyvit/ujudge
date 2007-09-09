class PerMemberValue < ActiveRecord::Base
  belongs_to :member
  belongs_to :field
  
  def valid_data?(errors)
    if self.field.required? && (value.nil? || value == '')
      errors.add(self.field.name, "Обязательно должно быть указано")
      return false
    end
    return true
  end
end
