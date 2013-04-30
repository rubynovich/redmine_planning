require_dependency 'time_entry'

module PlanningPlugin
  module TimeEntryPatch
    def self.included(base)
      base.extend(ClassMethods)

      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable

        include EstimatedTimesHelper

        validate :validate_spent_on
        validate :validate_hours
        validate :validate_user_id
        validate :validate_comments
        validates_presence_of :comments

        if Rails::VERSION::MAJOR >= 3
          scope :for_issues, lambda{ |issue_ids|
            if issue_ids.any?
              { :conditions =>
                  ["issue_id IN (:issue_ids)",
                    {:issue_ids => issue_ids}]
              }
            end
          }

          scope :actual, lambda{ |start_date, due_date|
            if start_date.present? && due_date.present?
              { :conditions =>
                  ["spent_on BETWEEN :start_date AND :due_date",
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
        else
          named_scope :for_issues, lambda{ |issue_ids|
            if issue_ids.any?
              { :conditions =>
                  ["issue_id IN (:issue_ids)",
                    {:issue_ids => issue_ids}]
              }
            end
          }

          named_scope :actual, lambda{ |start_date, due_date|
            if start_date.present? && due_date.present?
              { :conditions =>
                  ["spent_on BETWEEN :start_date AND :due_date",
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
      end
    end

    module ClassMethods
    end

    module InstanceMethods
      def validate_spent_on
        issue = self.issue
        day = self.spent_on
        unless can_change_spent?(issue, day)
          errors.add :spent_on, :invalid
        end
      end

      def validate_hours
        return if self.hours.blank?
        total_sum = TimeEntry.where(:user_id => self.user_id, :issue_id => self.issue_id, :spent_on => self.spent_on).select(&:hours).compact.sum(&:hours)
        if total_sum + self.hours > 24.0
          errors.add :hours, I18n.t(:error_day_has_only_24_hours)
        end
        if total_sum + self.hours > 12.0
          errors.add :hours, I18n.t(:error_workday_has_only_12_work_hours)
        end
      end

      def validate_user_id
        if self.issue && self.issue.assigned_to && (self.issue.assigned_to != self.user || (self.issue.assigned_to.class == Group && !self.issue.assigned_to.users.include?(User.current)))
          errors.add :base, I18n.t(:error_not_assign_labor_of_others_yourself)
        end
      end

      def validate_comments
        if TimeEntry.where( :user_id => self.user_id,
                            :issue_id => self.issue_id,
                            :spent_on => self.spent_on,
                            :hours => self.hours,
                            :comments => self.comments).count.nonzero?
          errors.add :comments, I18n.t(:error_be_creative_in_the_comments)
        end
      end
    end
  end
end
