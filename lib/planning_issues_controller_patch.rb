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

      private

      def update_planning
        safe_params = {}
        [:start_date, :due_date, :assigned_to_id].each {|k| safe_params.merge!({k => params[:issue][k]}) if @issue.safe_attribute?("#{k}") && params[:issue][k].present?} if params[:issue]
        #raise safe_params.inspect
		    if @issue.try(:id)
          issue_params = @issue.attributes.symbolize_keys.merge(safe_params) #mega HARD CODE!!!
          if issue_params[:assigned_to_id].to_s != @issue.assigned_to_id.to_s
            PlanningConfirmation.sidekiq_delay.change_assigned_to_planning(issue_params, @issue)
          end

          if (issue_params[:due_date].try(:to_date) != @issue.due_date.try(:to_date)) || (issue_params[:start_date].try(:to_date) != @issue.start_date.try(:to_date))
            PlanningConfirmation.sidekiq_delay.change_dates_planning(issue_params, @issue)
          end
        end
      end

    end
  end
end
