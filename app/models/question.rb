
class Question < ActiveRecord::Base
	belongs_to :contest
	belongs_to :team
end
