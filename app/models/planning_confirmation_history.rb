class PlanningConfirmationHistory < ActiveRecord::Base
  unloadable
  belongs_to :planning_confirmation
  belongs_to :user
  belongs_to :deputed_user, class_name: 'User'
  scope :kgips, -> {where(:confirm_as_kgip => true)}
  scope :heads, -> {where(:confirm_as_head => true)}
end
