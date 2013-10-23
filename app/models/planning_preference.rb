class PlanningPreference < ActiveRecord::Base
  unloadable

  belongs_to :user

  serialize :preferences

end
