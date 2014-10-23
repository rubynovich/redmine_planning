class PlanningConfirmationHistory < ActiveRecord::Base
  unloadable
  belongs_to :planning_confirmation
end
