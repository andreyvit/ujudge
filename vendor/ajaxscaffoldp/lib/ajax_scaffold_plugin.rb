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
require 'ajax_scaffold'

# AjaxTable
module AjaxScaffold # :nodoc:

  # extend the class that include this with the methods in ClassMethods
  def self.included(base)
    super
    base.extend(ClassMethods)
  end

  # Start Helper module
  module Helper
    include AjaxScaffold::Common

    # default html for an input tag
    def default_input_block
      Proc.new { |record, column| "<div class=\"form-element\">\n  "+
                                  "<label for=\"#{record}_#{column.name}\">#{column.human_name}</label>\n  "+
                                  "#{input(record, column.name)}\n</div>\n" }
    end

    # create input tags for each field in a model
    def all_input_tags(record, record_name, options)
      input_block = options[:input_block] || default_input_block

      if !options[:exclude].blank?
        filtered_content_columns = record.content_columns.reject { |column| options[:exclude].include?(column.name) }
      else
        filtered_content_columns = record.content_columns
      end

      filtered_content_columns.collect{ |column| input_block.call(record_name, column) }.join("\n")
    end
  end

  module ClassMethods

    # Adds a swath of actions to the controller.
    def ajax_scaffold(model_id, options = {})
      options.assert_valid_keys(:class_name, :except, :rows_per_page, :suffix, :totals, :width, :rel_width)

      # set up a few variables for use in the code generation
      singular_name   = model_id.to_s
      class_name      = options[:class_name] || singular_name.camelize
      plural_name     = singular_name.pluralize
      rows_per_page   = options[:rows_per_page] || 25
      suffix          = options[:suffix] ? "_#{singular_name}" : ""
      prefix          = options[:suffix] ? "#{plural_name}_" : ""
      totals          = options[:totals].nil? ? nil : options[:totals].join(',').to_s
      width           = options[:width].nil? ? (options[:rel_width].nil? ? nil : options[:rel_width]*100 ) : options[:width]
      
      if (width) 
         dimensions = options[:width].nil? ? "%" : "px"
         width = width.to_s + dimensions
      end
      
      no_create, no_edit, no_delete = false, false, false
      if (options[:except])
        no_create     = options[:except].include?('create')
        no_edit       = options[:except].include?('edit')
        no_delete     = options[:except].include?('delete')
      end

      module_eval <<-"end_eval", __FILE__, __LINE__
        include AjaxScaffold::Common
        include AjaxScaffold::AjaxController::Common

        verify :method => :post, :only => [ :destroy#{suffix}, :create#{suffix}, :update#{suffix} ],
               :redirect_to => { :action => :#{prefix}table }

        after_filter :clear_flashes

        @@#{prefix}scaffold_columns = nil
        @@#{prefix}scaffold_total_columns = nil
        @@#{prefix}scaffold_columns_hash = nil

        def #{prefix}scaffold_total_columns
          csv_array = "#{totals}".length >= 1 ? CSV.parse_line("#{totals}") : []
          @@#{prefix}scaffold_total_columns ||= csv_array
        end

        def #{prefix}scaffold_columns
          @@#{prefix}scaffold_columns ||= build_#{prefix}scaffold_columns
        end

        def #{prefix}scaffold_columns_hash
          @@#{prefix}scaffold_columns_hash ||= build_#{prefix}scaffold_columns_hash
        end

        def #{prefix}table
          self.#{prefix}table_setup
          
          render#{suffix}_template(:action => 'table')
        end

        def #{prefix}table_setup
          update_params :default_scaffold_id => "#{singular_name}", :default_sort => nil, :default_sort_direction => default_#{prefix}sort_direction
          
          @show_wrapper = true if @show_wrapper.nil?
          @width = "#{width}"
          sort_sql = #{prefix}scaffold_columns_hash[current_sort(params)].sort_sql rescue default_#{prefix}sort
          sort = #{prefix}scaffold_columns_hash[current_sort(params)].sort rescue nil
          sort_direction = current_sort_direction(params)

          klass = Inflector.camelize("#{singular_name}").constantize
          order = sort.nil? ? sort_sql : sort
          #order += " " + sort_direction
          # modified by Andrey Tarantsov. had nil error here.
          order += " " + (sort_direction || "")
          options = { :order => order,
                      :conditions => conditions_for_#{plural_name}_collection,
                      :direction => current_sort_direction(params),
                      :per_page => #{rows_per_page} }

          count = count_#{plural_name}_collection(klass, options)
          @paginator = Paginator.new(self, count, #{rows_per_page}, current_page(params))

          if (sort.nil?)
            @collection = page_and_sort_#{plural_name}_collection(klass, options, @paginator)
          else
            @collection = page_and_sort_#{plural_name}_collection_with_method(klass, options, @paginator)
          end
        end

        # if multiple tables (suffix) then return to index (can be changed by overriding)
        # if single table return to list
        def #{prefix}return_to_main
          action = "#{suffix}" == "" ? "#{prefix}list" : "index"
          redirect_to :action => action
        end

        def update_#{prefix}table
          @show_wrapper = false # don't show the outer wrapper elements if we are just updating an existing scaffold
          if request.xhr?
            #{prefix}table_setup
            render#{suffix}_template(:action => 'table')
          else
            #{prefix}return_to_main
          end
        end

        def #{prefix}list
          render#{suffix}_template(:action => 'list.rhtml', :layout => true)
        end
      end_eval

      if(suffix=="")
        module_eval <<-"end_eval", __FILE__, __LINE__
          def index
            redirect_to(:action => :list)
          end
        end_eval
      end

      # now only create these methods if not excluded
      unless (no_create)
        module_eval <<-"end_eval", __FILE__, __LINE__
          def new#{suffix}
            @#{singular_name} = #{class_name}.new
            @successful = true

            return render#{suffix}_template(:action => 'new.rjs') if request.xhr?

            # Javascript disabled fallback
            if @successful
              @options = { :action => "create" }
              render#{suffix}_template(:action => "_new_edit.rhtml", :layout => true)
            else
              #{prefix}return_to_main
            end
          end

          def create#{suffix}
            begin
              create_#{singular_name}#{suffix}
            rescue
              flash[:error], @successful  = $!.to_s, false
            end

            return render#{suffix}_template(:action => 'create.rjs') if request.xhr?

            if @successful
              #{prefix}return_to_main
            else
              @options = { :scaffold_id => params[:scaffold_id], :action => "create" }
              render#{suffix}_template(:action => "_new_edit.rhtml", :layout => true)
            end
          end

          def create_#{singular_name}#{suffix}
              @#{singular_name} = #{class_name}.new(params[:#{singular_name}])
              @successful = @#{singular_name}.save
          end
        end_eval
      end

      unless (no_edit)
        module_eval <<-"end_eval", __FILE__, __LINE__
          def edit#{suffix}
            begin
              @#{singular_name} = #{class_name}.find(params[:id])
              @successful = !@#{singular_name}.nil?
            rescue
              flash[:error], @successful  = $!.to_s, false
            end

            return render#{suffix}_template(:action => 'edit.rjs') if request.xhr?

            if @successful
              @options = { :scaffold_id => params[:scaffold_id], :action => "update", :id => params[:id] }
              render#{suffix}_template(:action => "_new_edit.rhtml", :layout => true)
            else
              #{prefix}return_to_main
            end
          end

          def update#{suffix}
            begin
              update_#{singular_name}#{suffix}
            rescue
              flash[:error], @successful  = $!.to_s, false
            end

            return render#{suffix}_template(:action => 'update.rjs') if request.xhr?

            if @successful
              #{prefix}return_to_main
            else
              @options = { :action => "update" }
              render#{suffix}_template(:action => "_new_edit.rhtml", :layout => true)
            end
          end

          def update_#{singular_name}#{suffix}
              @#{singular_name} = #{class_name}.find(params[:id])
              @successful = @#{singular_name}.update_attributes(params[:#{singular_name}])
          end
        end_eval
      end

      unless (no_delete)
        module_eval <<-"end_eval", __FILE__, __LINE__
          def destroy#{suffix}
            begin
              @successful = #{class_name}.find(params[:id]).destroy
            rescue
              flash[:error], @successful  = $!.to_s, false
            end

            return render#{suffix}_template(:action => 'destroy.rjs') if request.xhr?

            # Javascript disabled fallback
            #{prefix}return_to_main
          end
        end_eval
      end

      module_eval <<-"end_eval", __FILE__, __LINE__
        def cancel#{suffix}
          @successful = true

          return render#{suffix}_template(:action => 'cancel.rjs') if request.xhr?

           # Javascript disabled fallback
          #{prefix}return_to_main
        end

        protected
          # Override this for custom selection conditions
          def conditions_for_#{plural_name}_collection
            nil
          end

          # Override to change the default sort from plural_name.id
          def default_#{prefix}sort
            "#{plural_name}.id"
          end

          # Override to change the default sort direction
          def default_#{prefix}sort_direction
            "asc"
          end

          # Returns the total number of items in the collection
          def count_#{plural_name}_collection(model, options)
            count_collection_for_pagination(model, options)
          end

          # Per model collection method, using sort_collection_by_method
          def page_and_sort_#{plural_name}_collection_with_method(model, options, paginator)
            # call: sort_collection_by_method(collection, column, order)
            order_parts = options[:order].split(' ')
            collection = model.find(:all, :conditions => options[:conditions],
                                    :joins => options[:join] || options[:joins],
                                    :include => options[:include],
                                    :select => options[:select])

            sort_collection_by_method(collection, order_parts[0], order_parts[1]).slice(paginator.current.offset,options[:per_page])
          end

          # Per model collection method delegates to Rails as default
          def page_and_sort_#{plural_name}_collection(model, options, paginator)
            find_collection_for_pagination(model, options, paginator)
          end

        private
          def render#{suffix}_template( options = {} )
            @scaffold_columns ||= #{prefix}scaffold_columns
            @scaffold_column_totals = #{prefix}scaffold_total_columns
            @scaffold_class = #{class_name}
            @scaffold_singular_name, @scaffold_plural_name = "#{singular_name}", "#{plural_name}"
            @scaffold_controller = "/" + self.class.to_s.sub(/Controller/, "").underscore
            @no_create = #{no_create}
            @no_edit   = #{no_edit}
            @no_delete = #{no_delete}
            @suffix    = "#{suffix}"
            @prefix    = "#{prefix}"

            # check for template in  following order:
            # views/scaffold_class/template
            # views/controller_class/template
            # views/ajax_scaffold/template

            action = options[:action]
            layout = options[:layout] || false
            if template_exists?("#{plural_name}/\#{action}")
              render(:action => "../#{plural_name}/\#{action}", :layout => layout)

            elsif template_exists?("\#{self.class.controller_path}/\#{action}")
              render(:action => action, :layout => layout)

            else
              render(:action => "../ajax_scaffold/\#{action}", :layout => layout)
            end
          end

          def build_#{prefix}scaffold_columns
            scaffold_columns = Array.new
            #{class_name}.content_columns.each do |column|
              scaffold_columns << ScaffoldColumn.new(#{class_name}, { :name => column.name })
            end
            scaffold_columns
          end

          def build_#{prefix}scaffold_columns_hash
            scaffold_columns_hash = Hash.new
            #{prefix}scaffold_columns.each do |scaffold_column|
              scaffold_columns_hash[scaffold_column.name] = scaffold_column
            end
            scaffold_columns_hash
          end

      end_eval

    # end ajax_scaffold method
    end
  # end ClassMethods
  end

# end AjaxTable
end

# override render here to ensure that the correct partial is picked up
module ::ActionView #:nodoc:
  class Base

    # Renders the template present at <tt>template_path</tt> (relative to the template_root).
    # The hash in <tt>local_assigns</tt> is made available as local variables.
    def render(options = {}, old_local_assigns = {}, &block) #:nodoc:
      if options.is_a?(String)
        render_file(options, true, old_local_assigns)
      elsif options == :update
        update_page(&block)
      elsif options.is_a?(Hash)
        options[:locals] ||= {}
        options[:use_full_path] = options[:use_full_path].nil? ? true : options[:use_full_path]

        if options[:file]
          render_file(options[:file], options[:use_full_path], options[:locals])
        elsif options[:partial] && options[:collection]
          partial = parse_partial_path(options[:partial])
          render_partial_collection(partial, options[:collection], options[:spacer_template], options[:locals])
        elsif options[:partial]
          partial = parse_partial_path(options[:partial])
          render_partial(partial, ActionView::Base::ObjectWrapper.new(options[:object]), options[:locals])
        elsif options[:inline]
          render_template(options[:type] || :rhtml, options[:inline], nil, options[:locals] || {})
        end
      end
    end

    def parse_partial_path(partial_path)
      path, partial_name = partial_pieces(partial_path)

      if partial_path.include?('/')
        unless (erb_template_exists?("#{path}/_#{partial_name}"))
          path, partial_name = partial_pieces(partial_name)
          partial_path = "#{path}/#{partial_name}"
        end
      end

      unless (erb_template_exists?("#{path}/_#{partial_name}"))
        partial_path = "ajax_scaffold/#{partial_name}"
      end

      partial_path
    end
  end

  module Helpers
    module AssetTagHelper
      # produces all the includes in one shot
      def ajax_scaffold_includes
        js = javascript_include_tag(:defaults, 'dhtml_history', 'rico_corner', 'ajax_scaffold')
        css = stylesheet_link_tag('ajax_scaffold')
        js + "\n" + css
      end
    end
  end
end




