module GroupedFormHelper
  class Form
    attr_accessor :url, :options, :params_for_url, :groups, :object_name
    attr_accessor :additional_code
  
    def initialize
      @url = {}
      @options = {}
      @params_for_url = []
      @groups = []
      @additional_code = ""
    end
  
    def to_s(helpers)
      helpers.form_tag(url, options, params_for_url) + 
        groups.collect {|g| g.to_s(helpers)}.join('') +
        helpers.end_form_tag + @additional_code
    end
  end

  class Group
    attr_accessor :number, :title, :items, :object_name, :id
  
    def initialize
      @items = []
    end
  
    def normalize
      result = []
      bundle = nil
      items.each do |item|
        unless bundle.nil? || bundle.accepts?(item)
          result << bundle
          bundle = nil 
        end
        bundle = item.bundle if bundle.nil?
        if bundle
          bundle.add(item)
        else
          result << item
        end
      end
      result << bundle unless bundle.nil?
      self.items = result
    end
  
    def to_s(helpers)
      normalize
      return <<-EOS
        <div #{if @id then 'id="' + @id + '"' else "" end} class="block">
          <h3 class="header"><span>#{number}.&nbsp;</span>#{title}</h3>
          <div class="body">
            #{items.collect {|x| x.to_s(helpers)}.join('')}
          </div>
        </div>
      EOS
    end
  end

  class HelpItem 
    attr_accessor :body, :klass
  
    def to_s(helpers)
      return <<-EOS
        <p class="help">
          #{body}
        </p>
      EOS
    end

    def bundle
      nil
    end
  end

  class FieldBundle
    attr_accessor :items
  
    def initialize
      @items = []
    end
  
    def accepts?(item)
      [FieldItem, WideFieldItem].include?(item.class)
    end
  
    def add(item)
      @items << item
    end
  
    def to_s(helpers)
      return <<-EOS
        <table class="fields">
          #{items.collect {|x| x.to_s(helpers)}.join('')}
        </table>
      EOS
    end
  end

  class FieldItem
    attr_accessor :id, :label, :body, :error, :comment_text,
                  :object_name, :method_name, :object,
                  :index, :postback_name, :klass
  
    def bundle
      FieldBundle.new
    end
  
    def klass_to_s
      if @klass.nil? then "" else %Q/ class="#{@klass}"/ end
    end
  
    def error_to_s(helpers)
      return '' if error.nil? || error.blank?
      return <<-EOS
        <tr#{klass_to_s} id="#{id}_erow"><td class="col1">&nbsp;</td><td class="error">
          #{error}
        </td></tr>
      EOS
    end
  
    def comment_to_s(helpers)
      return '' if comment_text.nil? || comment_text.blank?
      return <<-EOS
        <tr#{klass_to_s} id="#{id}_crow"><td class="col1">&nbsp;</td><td class="comment">
          #{comment_text}
        </td></tr>
      EOS
    end
  
    def to_s(helpers)
      return <<-EOS
        #{error_to_s(helpers)}
        <tr#{klass_to_s} id="#{id}_row">
          <th class="col1"><label for="#{id}">#{label}</label></th>
          <td>
            #{body}
          </td>
      </tr>  
      #{comment_to_s(helpers)}
      EOS
    end
  end

  class WideFieldItem
    attr_accessor :id, :body, :object_name, :method_name, :object,
                  :index, :row_id
  
    def bundle
      FieldBundle.new
    end
  
    def to_s(helpers)
      id_html = @row_id && %{ id="#{@row_id}"} || ""
      return <<-EOS
        <tr#{id_html}>
          <td colspan="2">
            #{body}
          </td>
      </tr>  
      EOS
    end
  end
end
