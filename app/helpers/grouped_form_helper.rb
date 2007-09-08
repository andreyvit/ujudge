require 'grouped_forms'

module GroupedFormHelper
  class AbstractState
    def initialize(builder)
      @builder = builder
      @level = @builder.erbout.length
    end
  protected
    def capture
      res = @builder.erbout[@level..-1]
      @builder.erbout[@level..-1] = ''
      return res
    end
  end
  
  class AbstractBuilder
    def initialize(view, binding)
      @view = view
      @erbout = eval('_erbout', binding)
      @states = Array.new
    end
    
    def method_missing(id, *args)
      @states.reverse_each do |state|
        return state.send(id, *args) if state.respond_to?(id)
      end
      super
    end
    
    def erbout
      @erbout
    end
  protected
    def do_in_substate(state, &block)
      @states.push(state)
      begin
        state.render(block)
      ensure
        @states.pop
      end
    end
  end
  
  
  class FieldBuilder
    def initialize(core, group, *args, &block)
      @product = FieldItem.new
      @core = core
      @group = group

      # defaults
      @product.object_name = group.object_name unless group.object_name.nil?

      # parse arguments
      self.args = args
      
      # complete options
      object_hint = nil
      @custom_id_gen = false
      if @product.object.nil? && !@product.object_name.nil?
        if eval("local_variables.include?('#{@product.object_name}')", block.binding)
          @product.object = eval("#{@product.object_name}", block.binding)
          if eval("local_variables.include?('#{@product.object_name}_postback_hint')", block.binding)
            object_hint = eval("#{@product.object_name}_postback_hint", block.binding)
          end
        else
          @product.object = core.view.instance_variable_get("@#{@product.object_name}")
          object_hint = core.view.instance_variable_get("@#{@product.object_name}_postback_hint")
        end
      end
      @custom_id_gen = ! object_hint.nil?
      object_hint = [@product.object_name] if object_hint.nil?
      @product.id ||= (object_hint + [@product.method_name]).collect {|x| x.to_s}.join("_")
      @product.postback_name ||= object_hint.first.to_s +
        (object_hint[1..-1] + [@product.method_name]).collect {|x| "[#{x}]"}.join("")
      
      @product.error ||= @product.object.errors.on(@product.method_name) unless @product.object.nil? || @product.method_name.nil?
      @product.error = @product.error.last if @product.error.is_a?(Array)

      # generate body
      @product.body = core.capture(self, &block)
      
      # store
      group.items << @product
    end
    
    def select(*args)
      self.method_missing(:select, *args)
    end
    
    def respond_to?(id)
      super || (!@product.object_name.nil? && @core.view.respond_to?(id))
    end
    
    def postback_id
      @product.id
    end
    
    def postback_id_ex(s)
      @product.id + "_" + s 
    end
    
    def postback_name
      @product.postback_name
    end
    
    def postback_value
      @product.object.send(@product.method_name)
    end
    
    def postback_name_ex(x)
      @product.postback_name.gsub(/\]$/, "(#{x})]")
    end
    
    def method_missing(id, *args)
      case id
        when :text_field
          options = {:type => "text", :id => postback_id, :name => postback_name,
            :value => postback_value}
          options.update(args.last) if args.size > 0 && args.last.is_a?(Hash)
          return @core.view.tag(:input, options)
        when :textarea_field
          options = {:id => postback_id, :name => postback_name}
          options.update(args.last) if args.size > 0 && args.last.is_a?(Hash)
          return @core.view.content_tag(:textarea, postback_value, options)
        when :date_field
          core_options = {:id => postback_id, :name => postback_name, :class => 'narrow'}
          core_options.update(args.last) if args.size > 0 && args.last.is_a?(Hash)
          
          date = postback_value
          
          day_options = []
          1.upto(31) do |day|
               day_options << ((date && (date.kind_of?(Fixnum) ? date : date.day) == day) ?
                 %(<option value="#{day}" selected="selected">#{day}</option>\n) :
                 %(<option value="#{day}">#{day}</option>\n)
               )
             end
          
          day_info = core_options.dup
          day_info.update({:id => postback_id_ex("3i"), :name => postback_name_ex("3i")})
             
          month_options = []
          month_names = Date::MONTHNAMES
     
          1.upto(12) do |month_number|
            month_name = month_names[month_number]
            month_options << ((date && (date.kind_of?(Fixnum) ? date : date.month) == month_number) ?
              %(<option value="#{month_number}" selected="selected">#{month_name}</option>\n) :
              %(<option value="#{month_number}">#{month_name}</option>\n)
            )
          end     
          
          month_info = core_options.dup
          month_info.update({:id => postback_id_ex("2i"), :name => postback_name_ex("2i")})
          
          year_options = []
          y = date ? (date.kind_of?(Fixnum) ? (y = (date == 0) ? Date.today.year : date) : date.year) : Date.today.year
 
          start_year, end_year = Time.now.year - 100, Time.now.year - 10
          step_val = start_year < end_year ? 1 : -1
 
          start_year.step(end_year, step_val) do |year|
            year_options << ((date && (date.kind_of?(Fixnum) ? date : date.year) == year) ?
              %(<option value="#{year}" selected="selected">#{year}</option>\n) :
              %(<option value="#{year}">#{year}</option>\n)
            )
          end
          
          year_info = core_options.dup
          year_info.update({:id => postback_id_ex("1i"), :name => postback_name_ex("1i")})
               
          return @core.view.content_tag(:select, day_options, day_info) +
            @core.view.content_tag(:select, month_options, month_info) +
            @core.view.content_tag(:select, year_options, year_info)
        when :select_tag
          options = {:id => postback_id, :name => postback_name}
          options.update(args.pop) if args.size > 0 && args.last.is_a?(Hash)
          return @core.view.content_tag(:select, args.first, options)
      end
      if !@product.object_name.nil? && @core.view.respond_to?(id)
        opts = Hash.new
        opts[:object] = @product.object unless @product.object.nil?
        args.each do |arg|
          arg.update(opts) and break if arg.is_a?(Hash)
        end
        args.unshift(@product.method_name) unless @product.method_name.nil?
        args.unshift(@product.object_name)
        return @core.view.send(id, *args) 
      end
        
      super
    end
  private
    def args=(args)
      self.options = args.pop if args.last.is_a?(Hash)
      unless args.empty?
        raise ArgumentError, "You cannot specify both object/method name and :id option" unless @product.id.nil?
        raise ArgumentError, "You must specify both object and method names if you do not specify object name for the group" if @product.object_name.nil? && args.length == 1
        @product.method_name = args.pop unless args.empty?
        @product.object_name = args.pop unless args.empty?
      end
    end

    def options=(opts)
      opts.assert_valid_keys :id, :label, :error, :comment, :klass
      opts[:comment_text] = opts.delete(:comment) if opts[:comment]
      opts.each do |key, value|
        @product.send("#{key}=", value)
      end
    end
  end
  
  class WideFieldBuilder
    def initialize(core, group, *args, &block)
      @product = WideFieldItem.new
      @core = core
      @group = group

      # defaults
      @product.object_name = group.object_name unless group.object_name.nil?

      # parse arguments
      self.args = args
      
      # complete options
      @product.id ||= "#{@product.object_name}_#{@product.method_name}"
      if @product.object.nil? && !@product.object_name.nil?
        if eval("local_variables.include?('#{@product.object_name}')", block.binding)
          @product.object = eval("#{@product.object_name}", block.binding)
        else
          @product.object = core.view.instance_variable_get("@#{@product.object_name}")
        end
      end

      # generate body
      @product.body = core.capture(self, &block)
      
      # store
      group.items << @product
    end
    
    def select(*args)
      self.method_missing(:select, *args)
    end
    
    def respond_to?(id)
      super || (!@product.object_name.nil? && @core.view.respond_to?(id))
    end
    
    def method_missing(id, *args)
      if !@product.object_name.nil? && @core.view.respond_to?(id)
        opts = Hash.new
        opts[:object] = @product.object unless @product.object.nil?
        args.each do |arg|
          arg.update(opts) and break if arg.is_a?(Hash)
        end
        args.unshift(@product.method_name) unless @product.method_name.nil?
        args.unshift(@product.object_name)
        return @core.view.send(id, *args) 
      end
        
      super
    end
  private
    def args=(args)
      self.options = args.pop if args.last.is_a?(Hash)
      unless args.empty?
        raise ArgumentError, "You cannot specify both object/method name and :id option" unless @product.id.nil?
        raise ArgumentError, "You must specify both object and method names if you do not specify object name for the group" if @product.object_name.nil? && args.length == 1
        @product.method_name = args.pop unless args.empty?
        @product.object_name = args.pop unless args.empty?
      end
    end

    def options=(opts)
      opts.assert_valid_keys :id, :row_id
      opts.each do |key, value|
        @product.send("#{key}=", value)
      end
    end
  end
   
  class GroupBuilder
    def initialize(core, form, *args, &block)
      @product = Group.new
      @core = core
      @form = form

      # defaults
      @product.object_name = form.object_name unless form.object_name.nil?

      # parse arguments
      self.args = args
      
      # complete options
      if @product.number.nil?
        if @form.groups.empty?
          @product.number = '1'
        else
          @product.number = @form.groups.last.number.to_i + 1 rescue nil
        end
      end

      # the block is not supposed to produce anything but valid items
      core.execute(self, &block)
      
      # store
      form.groups << @product
    end
    
    def field(*args, &block)
      FieldBuilder.new(@core, @product, *args, &block)
    end
    
    def wide_field(*args, &block)
      WideFieldBuilder.new(@core, @product, *args, &block)
    end
    
    def help(*args, &block)
      item = HelpItem.new
      
      options = {}
      options.update(args.pop) if args.size > 0 && args.last.is_a?(Hash)
      options.assert_valid_keys :klass
      options.each { |key, value| item.send("#{key}=", value) }

      item.body = @core.capture(self, &block)
      @product.items << item
    end
  private
    def args=(args)
      self.options = args.pop if args.last.is_a?(Hash)
      raise ArgumentError, "Invalid number of arguments for call to group(), have #{args.yo_taml}" if args.length != 1
      @product.title = *args
    end

    def options=(opts)
      opts.assert_valid_keys :number, :object, :id
      opts[:object_name] = opts.delete(:object) if opts[:object].is_a?(Symbol) || opts[:object].is_a?(String)
      opts.each do |key, value|
        @product.send("#{key}=", value)
      end
    end
  end
   
  class FormBuilder
    def initialize(core, *args, &block)
      @product = Form.new
      @core = core

      # parse arguments
      self.send('args=', *args)
      
      # complete options
      
      # the block is not supposed to produce anything but groups
      @core.execute(self, &block)
      
      # store
      @core.product = @product
    end
    
    def <<(text)
      @product.additional_code << text      
    end
    
    def group(*args, &block)
      GroupBuilder.new(@core, @product, *args, &block)
    end
  private
    def args=(url = {}, options = {}, *params_for_url)
      @product.object_name = options.delete(:object) if options[:object]
      @product.url = url
      @product.options = options
      @product.params_for_url = params_for_url
    end
  end
  
  class Core
    attr_accessor :product
    attr_reader :view
    
    def initialize(view, binding)
      @view = view
      @additional_code = ""
    end
    
    def execute(sender, &block)
      @additional_code << capture(sender, &block)
    end
    
    def capture(sender, &block)
      erbout = eval('_erbout', block.binding)
      level = erbout.length
      yield sender
      res = erbout[level..-1]
      erbout[level..-1] = ''
      return res
    end
    
    def build(*args, &block)
      FormBuilder.new(self, *args, &block)
      self.product.additional_code << @additional_code
    end
  end

  def grouped_form(*args, &block)
    acore = GroupedFormHelper::Core.new(self, block.binding)
    acore.build(*args, &block)
    concat(acore.product.to_s(self), block.binding)
  end
  
end
