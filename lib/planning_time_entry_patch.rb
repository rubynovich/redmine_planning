require_dependency 'time_entry'

module PlanningPlugin
  module TimeEntryPatch
    def self.included(base)
      base.extend(ClassMethods)

      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable

        include EstimatedTimesHelper

        validate :validate_spent_on, if: ->{ self.issue.meeting_member.blank? rescue true }
        validate :validate_hours
        validate :validate_user_id, if: ->{ self.issue.meeting_member.blank? rescue true }
        validate :validate_comments


        validate :validate_time_confirmed

        validates_presence_of :comments

        belongs_to :planning_confirmation

        #validate :validate


        alias_method :editable_by_without_planning_plugin, :editable_by?
        alias_method :editable_by?, :editable_by_with_planning_plugin


        after_save :set_planning_confirmation_id

        #alias_method_chain :editable_by?, :planning_plugin

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

          scope :for_period, lambda{ |period|
            if period == "current_week"
              start_date = Date.today - Date.today.wday.days - 1.day
              due_date = start_date + 6.days
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

          named_scope :for_period, lambda{ |period|
            if period == "current_week"
              start_date = Date.today - Date.today.wday.days - 1.day
              due_date = start_date + 6.days
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

      def set_planning_confirmation_id
        if self.planning_confirmation.nil? || (! (self.planning_confirmation.date_start..self.planning_confirmation.date_start.end_of_week).include?(self.spent_on))
          pc = PlanningConfirmation.where(issue_id: self.issue_id, user_id: self.user_id, date_start: self.spent_on.beginning_of_week).first
          self.update_column(:planning_confirmation_id, pc.id) if pc.present? && pc.head_confirmation.nil? && pc.kgip_confirmation.nil?
        end
      end

      def editable_by_with_planning_plugin(usr)
        if editable_by_without_planning_plugin(usr)
          #check plannig
          PlanningConfirmation.where(issue_id: self.issue_id, user_id: self.user_id).where(["'kgip_confirmation' = ? OR head_confirmation = ?", true, true]).where(["date_start = ?", self.spent_on.beginning_of_week]).first.nil?
        else
          false
        end
      end


      def validate_time_confirmed
        if pc = PlanningConfirmation.where(issue_id: self.issue_id, user_id: self.user_id).where(["'kgip_confirmation' = ? OR head_confirmation = ?", true, true]).where(["date_start = ?", self.spent_on.beginning_of_week]).first
          if pc.kgip_confirmation && pc.head_confirmation
            errors.add :base, :time_error_both_confirmation
          elsif pc.kgip_confirmation
            errors.add :base, :time_error_kgip_confirmation
          elsif pc.head_confirmation
            errors.add :base, :time_error_head_confirmation
          end
          return false
        end
      end

      def validate_spent_on
        issue = self.issue
        day = self.spent_on
        unless can_change_spent?(issue, day)
          if (Setting[:plugin_redmine_planning][:issue_statuses].try(:to_a) || []).map{|i| i.to_i}.include?(issue.status_id.to_i)
            errors.add :base, l(:error_for_status_issue) % issue.status.name
            return false
          else
            errors.add :spent_on, :invalid
          end
        end
      end

      def validate_hours
        return if self.hours.blank?
        total_sum = TimeEntry.where(user_id: self.user_id, issue_id: self.issue_id, spent_on: self.spent_on).select(&:hours).compact.sum(&:hours)
        if total_sum + self.hours > 24.0
          errors.add :hours, I18n.t(:error_day_has_only_24_hours)
        end
#        if total_sum + self.hours > 12.0
#          errors.add :hours, I18n.t(:error_workday_has_only_12_work_hours)
#        end
      end

      def validate_user_id
        if self.issue && self.issue.assigned_to
          if self.issue.assigned_to.is_a?(Group)
            if !self.issue.assigned_to.users.include?(self.user)
              errors.add :base, I18n.t(:error_not_member_labor_group)
            end
          elsif self.issue.assigned_to != self.user
            errors.add :base, I18n.t(:error_not_assign_labor_of_others_yourself)
          end
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

      def validate_issue_id
        unless self.issue.leaf? # родительская задача
          errors.add :issue, I18n.t(:error_parent_issue_has_no_time)
        end
      end

    end
  end
end
