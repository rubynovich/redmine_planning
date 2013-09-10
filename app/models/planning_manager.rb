class PlanningManager < ActiveRecord::Base
  unloadable
  
  belongs_to :user

  has_many :subordinates

  validates_presence_of :user_id  
  validates_uniqueness_of :user_id
  
end
