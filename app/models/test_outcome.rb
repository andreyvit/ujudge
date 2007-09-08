class TestOutcome
  attr_reader :id, :short_display_name, :display_name, :color

  def initialize(id, short_display_name, display_name, color)
    @id = id
    @short_display_name = short_display_name
    @display_name = display_name
    @color = color
  end
  
  def self.add(outcome)
    @@table[outcome.id] = outcome
  end
  
  def self.init_table
    @@table = {}
    add(TestOutcome.new('ok', 'ok', "ПРИНЯТА", 'lime'))
    add(TestOutcome.new('wa', 'WA', "Неверный ответ", 'red'))
    add(TestOutcome.new('no_output_file', 'NF', "Не создан выходной файл", 'maroon'))
    add(TestOutcome.new('presentation_error', 'PE', "Неверный формат вывода", 'maroon'))
    add(TestOutcome.new('runtime_error', 'RE', "Решение завершилось с ошибкой", 'fuchsia'))
    add(TestOutcome.new('deadlock', 'DL', "Превышен лимит астрономического времени", 'aqua'))
    add(TestOutcome.new('time_limit', 'TL', "Превышен лимит времени", 'aqua'))
    add(TestOutcome.new('memory_limit', 'ML', "Превышен лимит памяти", 'aqua'))
  end
  
  self.init_table
  
  def self.find_by_id(id)
    @@table[id.to_s]
  end
end