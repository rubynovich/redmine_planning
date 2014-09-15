class PlanningConfirmationComment < ActiveRecord::Base
  unloadable
  belongs_to :planning_confirmation
  belongs_to :user
  scope :kgips, -> {where(:confirmation_type => 0)}
  scope :heads, -> {where(:confirmation_type => 1)}
end
