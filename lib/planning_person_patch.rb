require_dependency 'department'

module PlanningPlugin
  module PersonPatch
    def self.included(base)
      base.extend(ClassMethods)

      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable


        after_update :create_or_change_planning
        after_create :create_or_change_planning
      end
    end

    module ClassMethods
    end

    module InstanceMethods
      def create_or_change_planning
      	Rails.logger.error(("create_or_change_planning: " + self.inspect).red)
        PlanningConfirmation.create_or_change_planning(self)
      end

    end
  end
end
