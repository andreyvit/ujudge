class ChangeCompilerSettings < ActiveRecord::Migration
  def self.up
    rename_column "compilers", "executable", "compiler"
    rename_column "compilers", "extensions", "extension"
    add_column "compilers", "compiler_flags", :string
    add_column "compilers", "binaries", :string
    rename_column "compilers", "fixed_source_name", "source_name"
    add_column "compilers", "interpreter", :string
    remove_column "compilers", "type"
  end

  def self.down
    rename_column "compilers", "extension", "extensions"
    remove_column "compilers", "compiler_flags"
    remove_column "compilers", "binaries"
    rename_column "compilers", "source_name", "fixed_source_name"
    remove_column "compilers", "interpreter"
    rename_column "compilers", "compiler", "executable"
    add_column "compilers", "type", :string
    execute "update compilers set type='Compiler'"
  end
end
