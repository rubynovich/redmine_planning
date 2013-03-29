require_dependency 'timelog_helper'

module PlanningPlugin
  module TimelogHelperPatch
    def self.included(base)
      base.extend(ClassMethods)

      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable

        begin
          alias_method_chain :entries_to_csv, :patch
        rescue
          #TODO for Redmine 2.3
        end
      end
    end

    module ClassMethods
    end

    module InstanceMethods
      def entries_to_csv_with_patch(entries)
        issue_ids = entries.map(&:issue_id).uniq
        spent_ons = entries.map(&:spent_on)
        start_date = spent_ons.min
        end_date = spent_ons.max
        estimated_times = EstimatedTime.for_issues(issue_ids).actual(start_date, end_date).all
        decimal_separator = l(:general_csv_decimal_separator)
        custom_fields = TimeEntryCustomField.find(:all)
        export = FCSV.generate(:col_sep => l(:general_csv_separator)) do |csv|
          # csv header fields
          headers = [l(:field_spent_on),
                     l(:field_user),
                     l(:field_activity),
                     l(:field_project),
                     l(:field_issue),
                     l(:field_tracker),
                     l(:field_subject),
                     l(:label_spent),
                     l(:field_comments),
                     l(:label_plan),
                     l(:field_comments)
                     ]
          # Export custom fields
          headers += custom_fields.collect(&:name)

          csv << headers.collect {|c| Redmine::CodesetUtil.from_utf8(
                                         c.to_s,
                                         l(:general_csv_encoding) )  }
          # csv lines
          entries.each do |entry|
            fields = [format_date(entry.spent_on),
                      entry.user,
                      entry.activity,
                      entry.project,
                      (entry.issue ? entry.issue.id : nil),
                      (entry.issue ? entry.issue.tracker : nil),
                      (entry.issue ? entry.issue.subject : nil),
                      entry.hours.to_s.gsub('.', decimal_separator),
                      entry.comments
                      ]
            plan = estimated_times.detect{ |et| (et.user == entry.user)&&(et.issue == entry.issue)&&(entry.spent_on == et.plan_on) }
            estimated_times -= [plan]
            fields += if plan.present?
              [plan.hours.to_s.gsub('.', decimal_separator), plan.comments]
            else
              [nil,nil]
            end
            fields += custom_fields.collect {|f| show_value(entry.custom_field_values.detect {|v| v.custom_field_id == f.id}) }

            csv << fields.collect {|c| Redmine::CodesetUtil.from_utf8(
                                         c.to_s,
                                         l(:general_csv_encoding) )  }
          end
        end
        export
      end
    end
  end
end
