#--
# AjaxScaffoldPlugin by Scott Rutherford, UK, July 2006
# scott@cominded.com, scott@caronsoftware.com
#
# Adapted from the excellent AjaxScaffold by Richard White
# www.ajaxscaffold.com
#
# Uses DhtmlHistory by Brad Neuberg, bkn3@columbia.edu
# http://codinginparadise.org
#
# Uses Querystring by Adam Vandenberg
# http://adamv.com/dev/javascript/querystring
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

# AjaxTable
module AjaxScaffold # :nodoc:
  class ScaffoldColumn   
    attr_reader :name, :eval, :sort_sql, :label, :sort, :class_name, :total
    
    # Only options[:name] is required. It will infer the eval and sort values
    # based on the given class.    
    def initialize(klass, options)
      @name = options[:name]
      @eval = options[:eval].nil? ? "row." + @name : options[:eval]
      @label = options[:label].nil? ? Inflector.titleize(@name) : options[:label]      
      @sortable = options[:sortable].nil? ? true : options[:sortable]      
      @sort_sql = options[:sort_sql].nil? ? klass.table_name + "." + @name : options[:sort_sql] unless !@sortable
      @sort = options[:sort]
      @class_name = options[:class_name].nil? ? "" : options[:class_name]
      @total = 0
    end
    
    def add_to_total(value)
      @total += value.to_f
    end
    
    def sortable? 
      @sortable
    end  
  end
    
  module Common
    def current_sort(params)
      session[params[:scaffold_id]][:sort]
    end
  
    def current_sort_direction(params)
      session[params[:scaffold_id]][:sort_direction]
    end  
    
    def current_page(params)
      session[params[:scaffold_id]][:page]
    end
  end 
  
  module AjaxController
    module Common
      def clear_flashes 
        if request.xhr? 
          flash.keys.each do |flash_key|
            flash[flash_key] = nil
          end
        end
      end

      def store_or_get_from_session(id_key, value_key)
        session[id_key][value_key] = params[value_key] if !params[value_key].nil?
        params[value_key] ||= session[id_key][value_key]
      end

      def update_params(options)
        @scaffold_id = params[:scaffold_id] ||= options[:default_scaffold_id]
        session[@scaffold_id] ||= {:sort => options[:default_sort], :sort_direction => options[:default_sort_direction], :page => 1}

        store_or_get_from_session(@scaffold_id, :sort)
        store_or_get_from_session(@scaffold_id, :sort_direction)
        store_or_get_from_session(@scaffold_id, :page)
      end
            
      def sort_collection_by_method(collection, column, order)
        # sort in place (sort!) using block 
        collection.sort!{|line1, line2| sort_lines_by_column(line1, line2, column, order)}
      end

      def sort_lines_by_column(line1, line2, column, sort_order)
        # Compare each lines column values with <=>
        value1 = eval_method_string(line1, column)
        value2 = eval_method_string(line2, column)
        if (value1.nil?)
          res = -1
        elsif (value2.nil?)
          res = 1
        else 
          res = (value1 != nil ? value1 : "") <=> (value2 != nil ? value2 : "")
        end 
        # Reverse result if not asc
        sort_order == 'asc' ? res : res * -1
      end         
      
      def eval_method_string(object, method_str)
        # need to eval each section of the method string as this could return nil
        # at any point.
        methods = method_str.split('.')
        methods.each do |m|
          object = eval("object.#{m}") rescue nil
          return object if object.nil?
        end  
        object
      end
    end
  end 

  # Start Helper module
  module Helper
    include AjaxScaffold::Common
    
    def show_totals_for_column?(column)
      @scaffold_column_totals.include?(column)
    end
    
    def show_column_totals?
      @scaffold_column_totals.size > 0
    end
    
    # return the base path to search for a partial
    def scaffold_partial_path(partial)
      @scaffold_plural_name+'/'+partial
    end

    # number of columns in a table
    def num_columns
      @scaffold_columns.length + 1 
    end
            
    def format_column(column_value) 
      if column_empty?(column_value) 
        empty_column_text  
      elsif column_value.instance_of? Time
        format_time(column_value)
      elsif column_value.instance_of? Date
        format_date(column_value)
      else 
        column_value.to_s
      end
    end

    def format_time(time)
      time.strftime("%m/%d/%Y %I:%M %p")
    end 
  
    def format_date(date) 
      date.strftime("%m/%d/%Y")
    end 
  
    def column_empty?(column_value)
      column_value.nil? || (column_value.empty? rescue false)
    end
    
    def empty_column_text
      "-"
    end  
  
    # Generates a temporary id for creating a new element
    def generate_temporary_id
      (Time.now.to_f*1000).to_i.to_s
    end 
  
    def pagination_ajax_links(paginator, params)
      pagination_links_each(paginator, {}) do |n|
        link_to_remote n, 
           { :url => params.merge(:page => n ),
             :loading => "Element.show('#{loading_indicator_id(params.merge(:action => 'pagination'))}');",
             :update => scaffold_content_id(params) },
           { :href => url_for(params.merge(:page => n )) }
      end 
    end
  
    def column_sort_direction(column_name, params)
      column_name && current_sort_direction(params) == "asc" ? "desc" : "asc"
    end
  
    def column_class(column, column_value, sort_column)
      class_name = String.new
      class_name += "empty " if column_empty?(column_value)
      class_name += "sorted " if (!sort_column.nil? && column.name == sort_column)
      class_name += "#{column.class_name} " unless column.class_name.nil?
      class_name
    end
  
    def loading_indicator_tag(options)
      image_filename = "indicator.gif"
      "<img src=\"/images/#{image_filename}\" style=\"display: none;\" id=\"#{loading_indicator_id(options)}\" alt=\"loading indicator\" class=\"loading-indicator\" />"
    end  
  
    # The following are a bunch of helper methods to produce the common table view id's
  
    def scaffold_content_id(options)
      "#{options[:scaffold_id]}-content"
    end
  
    def scaffold_column_header_id(options)
      "#{options[:scaffold_id]}-#{options[:column_name]}-column"
    end
  
    def scaffold_tbody_id(options)
      "#{options[:scaffold_id]}-tbody"
    end

    def scaffold_messages_id(options)
      "#{options[:scaffold_id]}-messages"
    end 
  
    def empty_message_id(options)
      "#{options[:scaffold_id]}-empty-message"
    end 
  
    def element_row_id(options)
      "#{options[:scaffold_id]}-#{options[:action]}-#{options[:id]}-row"
    end
  
    def element_cell_id(options)
      "#{options[:scaffold_id]}-#{options[:action]}-#{options[:id]}-cell"
    end
  
    def element_form_id(options)
      "#{options[:scaffold_id]}-#{options[:action]}-#{options[:id]}-form"
    end 

    def loading_indicator_id(options)
      if options[:id].nil?
        "#{options[:scaffold_id]}-#{options[:action]}-loading-indicator"
      else
        "#{options[:scaffold_id]}-#{options[:action]}-#{options[:id]}-loading-indicator"
      end
    end

    def element_messages_id(options)
      "#{options[:scaffold_id]}-#{options[:action]}-#{options[:id]}-messages"
    end 
  end
  # End of Helper module
end




