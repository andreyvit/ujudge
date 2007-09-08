
class ListingColumn
  attr_reader :table, :method, :caption
  
  def initialize(table, info)
    @table = table
    @method = info[:method]
    @caption = info[:caption]
    @show = false
    info[:show] = [:default] if info[:show] == true
    @default_show = true if info[:show].is_a?(Array) && info[:show].include?(:default)
  end
  
  def name
    @method.to_s
  end
  
  def unique_id
    @table.name + "_S_" + name
  end
  
  def value_of(root)
    @table.model_instance_of(root).send(@method)
  end
  
  def show=(v)
    @show = v
  end
  
  def show?
    @show || false
  end
  
  def show_by_default?
    @default_show
  end
  
  def friendly_column_name
    if table.derived? then "#{table.caption} - " else "" end + caption
  end
end

class ListingTable
  attr_reader :parent, :model, :columns, :columns_hash, :caption
  
  def initialize(parent, model, path)
    @parent = parent
    @model = model
    @columns = []
    @columns_hash = {}
    @path = path
  end
  
  def load
    info = @model.listing_info
    info[:columns].each do |col|
      next if col[:priv] && !@parent.user.allow?(col[:priv])
      c = ListingColumn.new(self, col)
      @columns << c
      @columns_hash[c.name] = c
    end
    
    info[:associations].each do |assoc|
      refl = @model.reflect_on_association(assoc[:name])
      t = ListingTable.new(@parent, refl.klass, @path + [assoc[:name]])
      @parent.add_table(t)
    end
    
    @caption = info[:caption]
  end
  
  def derived?
    @path.size > 0
  end
  
  def name
    @model.table_name
  end
  
  def model_instance_of(root)
    @path.inject(root) { |obj, method| obj.send(method) }
  end
end

class Listing
  attr_reader :user, :tables, :tables_hash
  
  def initialize(user, classes)
    @user = user
    @tables = []
    @tables_hash = {}
    classes.each do |c|
      add_table(ListingTable.new(self, c, []))
    end
  end
  
  def add_table(t)
    @tables << t
    @tables_hash[t.name] = t
    t.load
  end
  
  def column_from_uid(uid)
    table_name, column_name = uid.split('_S_', 2)
    table = @tables_hash[table_name]
    return nil if table.nil?
    table.columns_hash[column_name]
  end
  
  def handle_postback(data)
    return if data.nil?
    for uid, value in data
      col = column_from_uid(uid)
      col.show = (value == "1") unless col.nil?
    end
  end
  
  def set_default_visibility
    @tables.each do |t|
      t.columns.each { |c| c.show = c.show_by_default? }
    end
  end
  
  def column_names
    r = []
    @tables.each do |t|
      t.columns.each do |c|
        next unless c.show?
        r << c.friendly_column_name
      end
    end
    r
  end
  
  def column_values(root)
    r = []
    @tables.each do |t|
      t.columns.each do |c|
        next unless c.show?
        r << c.value_of(root)
      end
    end
    r
  end
end

