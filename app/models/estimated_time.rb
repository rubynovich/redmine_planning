class EstimatedTime < ActiveRecord::Base
  unloadable
  
  belongs_to :user
  belongs_to :project
  belongs_to :issue
  
  before_save :add_info
  
  validates_presence_of :issue_id, :hours, :plan_on
  validates_numericality_of :hours
  validates_uniqueness_of :issue_id, :scope => [:user_id, :plan_on]
  validate :validate_plan_on
  
  def add_info
    if self.valid?
      self.tyear = plan_on.year
      self.tmonth = plan_on.month
      self.tweek = plan_on.cweek
      self.user_id = User.current.id
      self.project_id = Issue.find(self.issue_id).project.id
    end
  end
  
  def validate_plan_on
    issue = self.issue
    day = self.plan_on
    unless day && can_change_plan?(issue, day)
#    (issue.start_date && (issue.start_date <= day))&&
#      (issue.due_date && (day <= issue.due_date))&&(1.day.ago < day)&& 
#      !issue.status.is_closed?
      
      errors.add :plan_on, :invalid
    end
  end
  
  named_scope :for_issues, lambda{ |issue_ids|
    { :conditions => 
        ["issue_id IN (:issue_ids)",
          {:issue_ids => issue_ids}]
    }      
  }
  
  named_scope :actual, lambda{ |start_date, due_date|
    if start_date.present? && due_date.present?
      { :conditions => 
          ["plan_on BETWEEN :start_date AND :due_date",
            {:start_date => start_date, :due_date => due_date}]
      }
    end          
  }
  
  named_scope :for_user, lambda{ |user_id| 
    if user_id.present?
      { :conditions => 
        {:user_id => user_id}
      }            
    end
  }  
end
