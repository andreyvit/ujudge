class AddCompilerOptions < ActiveRecord::Migration
  def self.up
    add_column "compilers", "fixed_source_name", :string, :null => true
    add_column "compilers", "platform", :string, :null => true
  end

  def self.down
    remove_column "compilers", "fixed_source_name"
    remove_column "compilers", "platform"
  end
end
