require File.dirname(__FILE__) + '/../test_helper'

class ContestTest < Test::Unit::TestCase
  fixtures :contests

	NEW_CONTEST = {}	# e.g. {:name => 'Test Contest', :description => 'Dummy'}
	REQ_ATTR_NAMES 			 = %w( ) # name of fields that must be present, e.g. %(name description)
	DUPLICATE_ATTR_NAMES = %w( ) # name of fields that cannot be a duplicate, e.g. %(name description)

  def setup
    # Retrieve fixtures via their name
    # @first = contests(:first)
  end

  def test_raw_validation
    contest = Contest.new
    if REQ_ATTR_NAMES.blank?
      assert contest.valid?, "Contest should be valid without initialisation parameters"
    else
      # If Contest has validation, then use the following:
      assert !contest.valid?, "Contest should not be valid without initialisation parameters"
      REQ_ATTR_NAMES.each {|attr_name| assert contest.errors.invalid?(attr_name.to_sym), "Should be an error message for :#{attr_name}"}
    end
  end

	def test_new
    contest = Contest.new(NEW_CONTEST)
    assert contest.valid?, "Contest should be valid"
   	NEW_CONTEST.each do |attr_name|
      assert_equal NEW_CONTEST[attr_name], contest.attributes[attr_name], "Contest.@#{attr_name.to_s} incorrect"
    end
 	end

	def test_validates_presence_of
   	REQ_ATTR_NAMES.each do |attr_name|
			tmp_contest = NEW_CONTEST.clone
			tmp_contest.delete attr_name.to_sym
			contest = Contest.new(tmp_contest)
			assert !contest.valid?, "Contest should be invalid, as @#{attr_name} is invalid"
    	assert contest.errors.invalid?(attr_name.to_sym), "Should be an error message for :#{attr_name}"
    end
 	end

	def test_duplicate
    current_contest = Contest.find_first
   	DUPLICATE_ATTR_NAMES.each do |attr_name|
   		contest = Contest.new(NEW_CONTEST.merge(attr_name.to_sym => current_contest[attr_name]))
			assert !contest.valid?, "Contest should be invalid, as @#{attr_name} is a duplicate"
    	assert contest.errors.invalid?(attr_name.to_sym), "Should be an error message for :#{attr_name}"
		end
	end
end

