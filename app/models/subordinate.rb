class Subordinate < ActiveRecord::Base
  unloadable

  belongs_to :planning_manager
  belongs_to :principal

  validates_uniqueness_of :principal_id, :scope => [:planning_manager_id]

end
