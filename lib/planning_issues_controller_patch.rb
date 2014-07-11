require_dependency 'issue'
require_dependency 'issue_status'

module PlanningPlugin
  module IssuesControllerPatch
    def self.included(base)
      base.extend(ClassMethods)

      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable

        #after_filter  :create_planning, :only => [:create]
        before_filter :update_planning, :only => [:update]

      end
    end

    module ClassMethods
    end

    module InstanceMethods

      def update_planning
        Rails.logger.error(("update_planning1: " + params.inspect).red)
		old_issue = Issue.find(params[:id]) 
        Rails.logger.error((params[:issue][:due_date].to_date.inspect + "  " + old_issue.due_date.to_date.inspect + "  " + 
        					params[:issue][:start_date].to_date.inspect + "  " + old_issue.start_date.to_date.inspect + "  " +
        					params[:issue][:assigned_to_id].to_s.inspect + "  " + old_issue.assigned_to_id.to_s.inspect).red)

		if params[:issue][:assigned_to_id].to_s != old_issue.assigned_to_id.to_s
			PlanningConfirmation.change_assigned_to_planning(params)
		end
        if (params[:issue][:due_date].to_date != old_issue.due_date.to_date) || (params[:issue][:start_date].to_date != old_issue.start_date.to_date) 
			PlanningConfirmation.change_dates_planning(params)
		end
      end

    end
  end
end
