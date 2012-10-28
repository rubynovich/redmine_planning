# encoding: utf-8
#
# Redmine - project management software
# Copyright (C) 2006-2011  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

module TimelogHelper
  def entries_to_csv(entries)
    issue_ids = entries.map(&:issue_id).uniq
    start_date = entries.max_by(&:spent_on)
    end_date = entries.min_by(&:spent_on)
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
