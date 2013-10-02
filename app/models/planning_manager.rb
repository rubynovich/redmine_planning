class PlanningManager < ActiveRecord::Base
  unloadable

  belongs_to :user

  has_many :subordinates

  validates_presence_of :user_id
  validates_uniqueness_of :user_id

  def active_subordinates
    User.where(id: self.subordinates.pluck(:principal_id)).sorted.active
  end

end
