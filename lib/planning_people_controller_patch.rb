require_dependency 'department'

module PlanningPlugin
  module PeopleControllerPatch
    def self.included(base)
      base.extend(ClassMethods)

      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable

        before_filter :set_old_time_confirm, :only=>[:update]
        after_filter :create_or_change_planning, :only=>[:update, :create]
      end
    end

    module ClassMethods
    end

    module InstanceMethods

      private

      def set_old_time_confirm
        @old_time_confirm = Person.where(id: params[:id]).first.try(:time_confirm)
      end

      def create_or_change_planning
        PlanningConfirmation.sidekiq_delay.create_or_change_planning(@person) if @old_time_confirm != @person.time_confirm
      end

    end
  end
end
