class AddRunOriginInfo < ActiveRecord::Migration
  def self.up
    add_column "runs", "origin_info", :string
  end

  def self.down
    remove_column "runs", "origin_info"
  end
end
