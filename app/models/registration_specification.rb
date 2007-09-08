class RegistrationSpecification < ActiveRecord::Base
  belongs_to :contest
  belongs_to :main_form, :class_name => 'Form'
end
