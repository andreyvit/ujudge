# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def checked_attr(bool)
    bool && "checked" || nil
  end
  
  def checked_text(bool)
    if bool then %Q/ checked="checked"/ else "" end
  end
  
  def track_appendable_field(field, selector)
    javascript_tag <<-EOT
        new AppendableSelect('#{field}', '#{selector}');
    EOT
  end
  
  def function(name, params) 
    page.send :record, "function #{name}(#{params.collect {|x| x.to_s}.join(', ')}) {"
    yield
    page.send :record, "}"
  end
  
  def confirm(prompt)
    page << "if(!confirm(" + page.send(:arguments_for_call, [prompt]) + ")) return false;"
  end
  
  class LayoutDomItem
    attr_accessor :id, :children, :attributes, :text
    
    include Enumerable
    
    def initialize
      @children = []
      @attributes = {}
    end
    
    def [](id)
      @children.find {|c| c.id == id}
    end
    
    def elements(id)
      @children.select {|c| c.id == id}
    end
        
    def each(&block)
      @children.each(&block)
    end
    
    def method_missing(id)
      attributes[id] || (r = self[id]) && r.text
    end
  end
  
  class LayoutDomBuilder
    attr_reader :items, :erbout, :root_items
    
    def initialize(&block)
      @erbout = eval('_erbout', block.binding)
      @items = []
      @root_items = []
    end
    
    def method_missing(id, *attributes, &block)
      last_item = LayoutDomItem.new
      if @items.empty? then @root_items else @items.last.children end << last_item
      @items << last_item
      last_item.id = id
      last_item.attributes = attributes
      
      level = @erbout.length
      yield self
      last_item.text = @erbout[level..-1]
      # last_item.text = nil if 0 == last_item.text.length
      @erbout[level..-1] = ''
      
      @items.pop
    end
    
    def root_item
      return nil if @root_items.empty?
      @root_items.first
    end
    
  end
  
  def widget(id, *attributes, &block)
    builder = LayoutDomBuilder.new(&block)
    builder.method_missing(id, *attributes, &block)
    # builder.erbout << "<pre>" + h(builder.root_item.to_yaml) + "</pre>\n"
    builder.erbout << render(:partial => "widgets/#{id}", :locals => {:data => builder.root_item})
  end
  
  def statement_file_path(statement)
    "#{ActionController::Base.asset_host}#{@controller.request.relative_url_root}/" +
      File.join("statements", statement.cookie, statement.filename)
  end
  
	def run_display_status(contest)
	  case contest.state
	  when -1
	    "Копируется на сервер"
	  when 0
	    "Только что сдано"
	  when 1
	    "В очереди"
	  when 2
	    "Тестируется"
	  when 3, 4
	    case contest.outcome
	    when 'compilation-error'
	      "Ошибка компиляции"
	    when 'tested'
	      ft = contest.failed_test
        case ft
        when :no_tests
          "В задаче нет тестов"
        when :accepted
          "ПРИНЯТО"
        when RunTest
          "#{ft.normal_display_outcome} на тесте #{ft.test_ord}"
        else
	        "Протестировано"
	      end
      when 'accepted'
        "ПРИНЯТО"
      when 'rejected'
        "Отклонено"
	    else
	      "Результат #{contest.outcome}"
	    end
	  when 10
	    "Отложено"
	  else
	    "Неизвестный статус #{contest.state}"
	  end
	end
  
  def run_status(run)
    if (3..4) === run.state && run.outcome == 'compilation-error'
      link_to(run_display_status(run), compilation_error_url(run.team.contest_id, run.team, run), {:target => '_new'})
    elsif (3..4) === run.state && run.outcome == 'tested'
      run_display_status(run)
    else
      run.display_status
    end
  end
  
  def spinner(params = {})
    params[:id] ||= last_spinner_id
    image_tag 'indicator-small.gif', {:alt => '', :style => 'display: none;'}.merge(params)
  end
  alias_method :small_indicator, :spinner
  
  def ajax_link_to(link_text, url, options = {})
    spinner_id = options.delete(:spinner) || next_spinner_id
    options.merge!(:loading => update_page {|page| page.show spinner_id},
        :completed => update_page {|page| page.hide spinner_id})
    options[:url] = url
    html_options = {:href => url}
    link_to_remote(link_text, options, html_options)
  end
  
  @@spinner_counter = 0
  
  def next_spinner_id
    @@spinner_counter += 1
    @@spinner_id = "spinner_#{Time.now.to_i}_#{@@spinner_counter}"
    last_spinner_id
  end
  
  def last_spinner_id
    @@spinner_id
  end
    
end
