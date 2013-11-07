class EstimatedTime < ActiveRecord::Base
  unloadable

  include EstimatedTimesHelper

  belongs_to :user
  belongs_to :project
  belongs_to :issue

  before_save :add_info
# before_destroy :validate_before_destroy

  validates_presence_of :issue_id, :hours, :plan_on, :comments
  validates_numericality_of :hours, allow_nil: true, message: :invalid
  validates_uniqueness_of :plan_on, scope: [:user_id, :issue_id]

  validate :validate_plan_on
  validate :validate_hours

  attr_accessor :google_calendar, :google_username, :google_password,
    :google_start_time

  scope :for_issues, lambda{ |issue_ids|
    { :conditions =>
      ["issue_id IN (:issue_ids)",
       {:issue_ids => issue_ids}]
    }
  }

  scope :actual, lambda{ |start_date, due_date|
    if start_date.present? && due_date.present?
      { :conditions =>
        ["plan_on BETWEEN :start_date AND :due_date",
         {:start_date => start_date, :due_date => due_date}]
      }
    elsif start_date.present?
      { :conditions =>
        ["plan_on >= :start_date",
         {:start_date => start_date}]
      }
    elsif due_date.present?
      { :conditions =>
        ["plan_on <= :due_date",
         {:due_date => due_date}]
      }
    end
  }

  scope :for_period, lambda{ |period|
    if period == "current_week"
      start_date = Date.today - Date.today.wday.days - 1.day
      due_date = start_date + 6.days
      { :conditions =>
        ["plan_on BETWEEN :start_date AND :due_date",
         {:start_date => start_date, :due_date => due_date}]
      }
    end
  }

  scope :for_user, lambda{ |user_id|
    if user_id.present?
      { :conditions =>
        {:user_id => user_id}
      }
    end
  }

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
    unless can_change_plan?(issue, day)
      errors.add :plan_on, :invalid
    end
  end

  def validate_hours
    issue = self.issue
    hours = self.hours
    if hours.is_a?(Float) && hours <= 0.0
      errors.add :hours, :invalid
    end
  end

  def validate_before_destroy
    issue = self.issue
    day = self.plan_on
    raise unless can_change_plan?(issue, day)
  end

end
