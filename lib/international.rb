
module International
  @@strings = {}
  
  def self.put(id, value, options = {})
    @@strings[id] = value
  end
  
  def self.get(id, options = {})
    @@strings[id]
  end
end

class Symbol
  def s(*args)
    International::get(self, *args)
  end
end

International::put :required_field_m, "Обязательно должен быть указан"
International::put :required_field_f, "Обязательно должна быть указана"
International::put :required_field_n, "Обязательно должно быть указано"
International::put :required_field_pl, "Обязательно должны быть указаны"