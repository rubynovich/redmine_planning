require_dependency 'department'

module PlanningPlugin
  module PeopleControllerPatch
    def self.included(base)
      base.extend(ClassMethods)

      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable
        after_filter :create_or_change_planning, :only=>[:update, :create]
      end
    end

    module ClassMethods
    end

    module InstanceMethods

      def create_or_change_planning
        PlanningConfirmation.create_or_change_planning(@person)
      end
      private :create_or_change_planning

    end
  end
end
