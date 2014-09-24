require_dependency 'issue'
require_dependency 'issue_status'

module PlanningPlugin
  module IssuePatch
    def self.included(base)
      base.extend(ClassMethods)

      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable

        has_many :planning_confirmations

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
        after_create :create_planning

        before_update do |issue|
          @old_issue_status_id = Issue.where(id:  issue.id).first.try(:status_id)
        end

        after_update do |issue|
          group_ids = Group.all.map(&:id)
          settings = Setting[:plugin_redmine_planning]
          if (group_ids.include?(issue.assigned_to_id)) && (@old_issue_status_id == settings[:new_issue_status].to_i) && (issue.status_id != @old_issue_status_id)
            journal = issue.journals.joins(:details).where(["journal_details.prop_key = 'status_id' and journal_details.old_value = ? and journal_details.value = ?",settings[:new_issue_status].to_s, issue.status_id.to_s ]).first
            if journal.present?
              JournalDetail.skip_callback(:create)
              JournalDetail.create(journal_id: journal.id, property: 'attr', prop_key: 'assigned_to_id', old_value: issue.assigned_to_id, value: journal.user_id)
              JournalDetail.set_callback(:create)
              issue.update_column(:assigned_to_id, journal.user_id)
            end
          end
        end

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

      def create_planning
        PlanningConfirmation.sidekiq_delay.create_planning(self)
      end

    end
  end
end
