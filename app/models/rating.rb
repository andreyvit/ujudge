class Rating < ActiveRecord::Base
  belongs_to :rating_definition
  
  serialize :value
  
  def self.set!(rundef, item_id, value)
    if item_id.nil?
      r = Rating.find(:first, :conditions => ['rating_definition_id = ? AND item_id IS NULL', rundef.id])
    else
      r = Rating.find(:first, :conditions => ['rating_definition_id = ? AND item_id = ?', rundef.id, item_id])
    end
    r = Rating.new(:rating_definition_id => rundef.id, :item_id => item_id) if r.nil?
    r.value = value
    r.save!
  end
  
  def inner_rating_definitions
    RatingDefinition.find(:all, :conditions => ["scope_type = ? AND parent_scope_id = ?", rating_definition.inner_scope_type,
self.item_id])
  end
  
  def teams
    unpack! if @results.nil?
    unpack_teams! if @teams.nil?
    @teams
  end
  
  def team_ids
    unpack! if @team_ids.nil?
    @team_ids
  end
  
  def result(team_id)
    unpack! if @results.nil?
    @results[team_id]
  end
  
  def fast_result(team_id)
    unpack_fast! if @fast_results.nil?
    @fast_results[team_id]
  end
  
  def trash!
    @results = nil
    @teams = nil
    @team_ids = nil
  end
  
private

  def unpack!
    @team_ids = []
    @results = {}
    self.value.each do |info|
      @team_ids << info[:team_id]
      @results[info[:team_id]] = OpenStruct.new(info)
    end
  end

  def unpack_fast!
    @team_ids = []
    @fast_results = {}
    self.value.each do |info|
      @team_ids << info[:team_id]
      @fast_results[info[:team_id]] = info
    end
  end

  def unpack_teams!
    @teams = Team.find(@team_ids)
    th = {}
    @teams.each { |t| th[t.id] = t }
    @teams = @team_ids.collect { |id| th[id] }
  end
  
end
