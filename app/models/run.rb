class Run < ActiveRecord::Base
  belongs_to :problem
  belongs_to :team
  belongs_to :compiler
  belongs_to :submittion
  
  has_many :tests, :class_name => "RunTest", :foreign_key => 'run_id'
  
  def failed_test
    Cache.get(all_tests_passed_cache_key) do
      all_tests = tests.find(:all, :order => 'run_tests.test_ord')
      return :no_tests if all_tests.size == 0
      x = all_tests.find { |test| test.outcome != 'ok' }
      return x unless x.nil?
      :accepted 
    end
  end
  
  def display_status
    case self.state
    when -1
      "Копируется на сервер"
    when 0
      "Только что сдано"
    when 1
      "В очереди"
    when 2
      "Тестируется"
    when 3, 4
      case self.outcome
      when 'compilation-error'
        "Ошибка компиляции"
      when 'tested'
        "Протестировано"
      else
        "Результат #{self.outcome}"
      end
    when 10
      "Отложено"
    else
      "Неизвестный статус #{self.state}"
    end
  end
  
  def has_test_results?
    [3,4].include?(self.state) && 'tested' == self.outcome
  end
  
private

  def all_tests_passed_cache_key
    "run-#{self.id}-failed-test"
  end
end
