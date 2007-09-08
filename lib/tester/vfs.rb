
# VFS is an abstraction of a tree data structure
module VFS
  
  class Item
    
    # Returns an array of all the children of this item. Must be implemented by subclasses.
    def children
      raise "Not implemented"
    end
    
    # Executes the given block for each child of this item.
    def each_child(&block)
      children.each(&block)
    end
    
    # Returns a textual string that uniquely identifies this child within its parent.
    # Valid characters are [a-zA-Z0-9_.-].
    def child_id
      raise "Not implemented"
    end
    
    def child_by_id(cid)
      each_child do |child|
        return child if child.child_id == cid
      end
    end
    
    def timestamp
      raise "Not implemented"
    end
    
    def properties
      raise "Not implemented"
    end
    
    def property(id)
      properties[id]
    end

    # Returns the name of the data file.
    def data_file
    end
    
    # Returns the data from the data file.
    def data_stream
      return nil if data_file.nil?
      File.open(data_file, 'rb') { |f| f.read }
    end
    
  end
  
  class PersistentItem
    
    ENVELOPE_FILE = 'envelope'
    PROPS_FILE = 'properties'
    DATA_FILE = 'data'
    
    def initialize(fspath, child_id = nil)
      @fspath     = fspath
      @child_id   = child_id
      @children   = nil
      @properties = nil
      @data_file  = nil
      @dirty = {}
    end
    
    def self.load(fspath, child_id = nil)
      PersistentItem.new(fspath, child_id)
    end
    
    def child_id
      read_envelope if @child_id.nil?
      @child_id
    end
    
    def child_id!(child_id)
      @child_id = child_id
    end
    
    def timestamp
      read_envelope if @timestamp.nil?
      @timestamp
    end
    
    def timestamp!(new_ts)
      @timestamp = new_ts
    end
    
    def properties
      read_properties if @properties.nil?
      @properties
    end
    
    def data_file
      if @data_file.nil?
        @data_file = File.join(@fspath, DATA_FILE)
        @data_file = false unless File.file?(@data_file)
      end
      return nil if @data_file == false
      @data_file
    end
    
    def data!(new_data)
      @data_file = File.join(@fspath, DATA_FILE)
      File.open(@data_file, 'wb') { |f| f.write(new_data) }
    end
    
  private

    def read_envelope
      fn = File.join(@fspath, ENVELOPE_FILE)
      if File.file?(fn)
        envelope = File.open(fn, 'rt') { |f| f.read }
        envelope = YAML.load(envelope)
        @child_id  = envelope[:child_id] || false
        @timestamp = envelope[:timestamp] || false
      else
        @child_id  = false
        @timestamp = false
      end
    end
    
    def write_envelope
      fn = File.join(@fspath, ENVELOPE_FILE)
      envelope = YAML.dump(:child_id => @child_id, :timestamp => @timestamp)
      File.open(fn, 'wt') { |f| f.write(envelope) }
    end

    def read_properties
      fn = File.join(@fspath, PROPS_FILE)
      if File.file?(fn)
        data = File.open(fn, 'rt') { |f| f.read }
        @properties = YAML.load(data)
      else
        @properties = {}
      end
    end
    
    def write_properties
      fn = File.join(@fspath, PROPS_FILE)
      data = YAML.dump(@properties)
      File.open(fn, 'wt') { |f| f.write(data) }
    end
    
  end
  
  class CachingProxyItem
    
    def initialize(options)
      if options[:parent]
        raise "Invalid call to CachingProxyItem(:parent, :cid)" unless options[:child_id]
        @parent   = options[:parent]
        @child_id = options[:child_id]
        @fspath   = @parent
      elsif options[:fspath]
        @fspath = options[:fspath]
      end
      
      @item = item
    end
    
  end
  
end
