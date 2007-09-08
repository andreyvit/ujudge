# Extension to make it easy to read and write data to a file.
class ActiveRecord::Base
  
  # Delete existing data and load fresh from file 
  def self.load_from_file(path=nil)
    path ||= "db/#{table_name}.yml"

    self.find_all.each { |old_record| old_record.destroy }

    if connection.respond_to?(:reset_pk_sequence!)
     connection.reset_pk_sequence!(table_name)
    end

    records = YAML::load( File.open( File.expand_path(path, RAILS_ROOT) ) )
    records.each do |record|
      record_copy = self.new(record.attributes)
      record_copy.id = record.id

      # For Single Table Inheritance
      klass_col = record.class.inheritance_column.to_sym
      if record[klass_col]
         record_copy.type = record[klass_col]
      end
      
      record_copy.save
    end
 
    if connection.respond_to?(:reset_pk_sequence!)
     connection.reset_pk_sequence!(table_name)
    end
  end

  # Writes to db/table_name.yml, or the specified file
  def self.dump_to_file(path=nil)
    path ||= "db/#{table_name}.yml"
    write_file(File.expand_path(path, RAILS_ROOT), 
      self.find(:all).collect.to_yaml)
  end

  # slightly better than what I posted to the blog:
  def self.dump_to_fixture(path = nil)
    path ||= yaml_fixture_path
    data = self.find(:all).inject("") do |s, record|
      self.columns.inject(s+"#{record.id}:\n") do |s, c|
        s + "  " + {c.name => record.attributes[c.name]}.to_yaml[5..-1].gsub("!binary |\n", "!binary |\n  ")
      end + "\n"
    end
    write_file(path, data)
  end
  
  def self.load_from_fixture(path = nil)
    path ||= yaml_fixture_path
    if yaml = YAML::load(File.open(path))
      yaml = yaml.value if yaml.respond_to?(:type_id) and yaml.respond_to?(:value)
      self.destroy_all
      yaml.each do |name, data|
        obj = self.new
        data.each do |name, value|
          obj.send("#{name}=", value)
        end
        obj.save_without_validation
      end
    else
      raise "YAML::load returned false"
    end
  rescue Exception => boom
    raise "a YAML error occured parsing #{yaml_fixture_path}. Please note that YAML must be consistently indented using spaces. Tabs are not allowed. Please have a look at http://www.yaml.org/faq.html\nThe exact error was:\n  #{boom.class}: #{boom}"
  end
  
  def self.yaml_fixture_path
    File.expand_path("test/fixtures/#{table_name}.yml", RAILS_ROOT)
  end

#  # Write a file that can be loaded with fixture :some_table in tests.
#  def self.to_fixture
#    write_file(File.expand_path("test/fixtures/#{table_name}.yml", RAILS_ROOT), 
#        self.find(:all).inject({}) { |hsh, record| 
#            hsh.merge("#{table_name.singularize}_#{record.id}" => record.attributes) 
#          }.to_yaml)
#    habtm_to_fixture
#  end
  
  # Write the habtm association table
  def self.habtm_to_fixture
    joins = self.reflect_on_all_associations.select { |j|
      j.macro == :has_and_belongs_to_many
    }
    joins.each do |join|
      hsh = {}
      connection.select_all("SELECT * FROM #{join.options[:join_table]}").each_with_index { |record, i|
        hsh["join_#{i}"] = record
      }
      write_file(File.expand_path("test/fixtures/#{join.options[:join_table]}.yml", RAILS_ROOT), hsh.to_yaml)
    end
  end

  def self.write_file(path, content)
    f = File.new(path, "w+")
    f.puts content
    f.close
  end

end
