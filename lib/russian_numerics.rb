module RussianNumerics
  @@numeric_cases = {
    1 => {:i => "первый", :p => "первом"},
    2 => {:i => "второй", :p => "втором"},
    3 => {:i => "третий", :p => "третьем"},
    4 => {:i => "четвертый", :p => "четвертом"},
    5 => {:i => "пятый", :p => "пятом"}
  }
  
  def self.russian_ordinal(n, case_name)
    RAILS_DEFAULT_LOGGER.warn "query #{n}, #{case_name}!"
    @@numeric_cases[n][case_name]
  end

  def self.rus_numeric(n, f1, f2, f3)
    # команда: 1 21 101
    # команды: 2 3 4 24 
    # команд: 5 6 7 8 9 10 11 12 13 .. 20 25 26 29 25
    case 
      when (5..20) === n || (n % 10) == 0 || (5..9) === (n % 10) then f3
      when (n % 10) == 1                  then f1
      else                                     f2
    end.gsub('#', n.to_s)
  end
  
  module IntegerMethods
    def russian(f1, f2, f3)
      RussianNumerics::rus_numeric(self, f1, f2, f3)
    end
    
    def to_russian_ordinal(case_name)
      RussianNumerics::russian_ordinal(self, case_name)
    end
  end
end

Fixnum.send(:include, RussianNumerics::IntegerMethods)

ActiveRecord::Errors.default_error_messages[:invalid_email] = "Нужно указать правильный адрес"
ActiveRecord::Errors.default_error_messages[:must_select] = "Нужно сделать выбор"