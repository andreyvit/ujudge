class University < ActiveRecord::Base
  has_many :teams
  
  validates_presence_of :name, :message => :required_field_n.s
  validates_length_of :name, :minimum => 5
  
  validates_presence_of :city, :message => :required_field_m.s
  validates_length_of :city, :minimum => 2
  
#  validates_presence_of :address, :message => :required_field_m.s
#  validates_length_of :address, :minimum => 6
  
#  validates_presence_of :person_for_invitation, :message => :required_field_m.s
#  validates_length_of :person_for_invitation, :minimum => 6
  
#  validates_format_of :zip, :with => /^[0-9]{6}$/, :message => "Должен состоять из 6 цифр"
  
  def self.listing_info
    {
      :caption => "Университет",
      :columns => [
        {:method => :name, :caption => "Название", :show => true},
        {:method => :city, :caption => "Город"},
        {:method => :address, :caption => "Адрес"},
        {:method => :zip, :caption => "Индекс"},
        {:method => :person_for_invitation, :caption => "Руководитель", :priv => :view_sensitive},
      ],
      :associations => [
      ]
    }
  end
end
