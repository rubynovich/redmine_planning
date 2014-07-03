require_dependency 'issue'
require_dependency 'issue_status'

module PlanningPlugin
  module IssuePatch
    def self.included(base)
      base.extend(ClassMethods)

      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable

        scope :in_project, lambda { |project|
          if project.present?
            { :conditions =>
              {
                :project_id => project.id
              }
            }
          end
        }

        scope :actual, lambda { |start_date, due_date|
          if start_date.present? && due_date.present?
            { :conditions =>
              ["#{IssueStatus.table_name}.is_closed = :is_closed OR #{Issue.table_name}.start_date BETWEEN :start_date AND :due_date OR #{Issue.table_name}.due_date BETWEEN :start_date AND :due_date OR #{Issue.table_name}.start_date <= :start_date AND #{Issue.table_name}.due_date >= :due_date", {:is_closed => false, :start_date => start_date, :due_date => due_date}],
              :include => :status
            }
          else
            { :conditions =>
              ["#{IssueStatus.table_name}.is_closed = :is_closed",
               {:is_closed => false}],
              :include => :status
            }
          end
        }

        scope :exclude_closed, lambda{ |exclude|
          if exclude.present?
            { :conditions =>
              ["#{IssueStatus.table_name}.is_closed = :is_closed",
               {:is_closed => false}],
              :include => :status
            }
          end
        }

        scope :exclude_not_planned, lambda{ |exclude, current_date|
          if exclude.present?
            { :conditions => ["#{Issue.table_name}.id IN (SELECT #{EstimatedTime.table_name}.issue_id FROM #{EstimatedTime.table_name} WHERE #{EstimatedTime.table_name}.plan_on BETWEEN :start_date AND :due_date)", {:start_date => current_date, :due_date => current_date + 6.days}]
            }
          end
        }

        scope :exclude_not_urgent, lambda{ |exclude, current_date|
          if exclude.present?
            { :conditions =>
              ["#{Issue.table_name}.due_date BETWEEN ? AND ?", current_date, current_date + 6.days]
            }
          end
        }

        scope :exclude_overdue, lambda{ |exclude, current_date|
          if exclude.present?
            { :conditions =>
              ["due_date > ?", current_date]
            }
          end
        }

      end
    end

    module ClassMethods
    end

    module InstanceMethods
      def user_spent_hours
        a = @total_spent_hours
        self_hours = self_and_descendants.sum("#{TimeEntry.table_name}.hours",
          :joins => "LEFT JOIN #{TimeEntry.table_name} ON #{TimeEntry.table_name}.issue_id = #{Issue.table_name}.id").to_f || 0.0
        self_hours = self_hours - descendants.sum("#{TimeEntry.table_name}.hours",
          :joins => "LEFT JOIN #{TimeEntry.table_name} ON #{TimeEntry.table_name}.issue_id = #{Issue.table_name}.id").to_f || 0.0
        self_hours
      end

    end
  end
end
