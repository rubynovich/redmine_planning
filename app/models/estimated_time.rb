class EstimatedTime < ActiveRecord::Base
  unloadable
  
  belongs_to :user
  belongs_to :project
  belongs_to :issue
  
  before_save :add_info
  
  validates_presence_of :issue_id, :hours, :plan_on
  validates_numericality_of :hours
  validates_uniqueness_of :issue_id, :scope => :user_id
  
  def add_info
    if self.valid?
      self.tyear = plan_on.year
      self.tmonth = plan_on.month
      self.tweek = plan_on.cweek
      self.user_id = User.current.id
      self.project_id = Issue.find(self.issue_id).project.id
    end
  end
end
