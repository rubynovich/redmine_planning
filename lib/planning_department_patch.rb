require_dependency 'department'

module PlanningPlugin
  module DepartmentPatch
    def self.included(base)
      base.extend(ClassMethods)

      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable


        after_update :change_head_planning
        after_create :change_head_planning
      end
    end

    module ClassMethods
    end

    module InstanceMethods
      def change_head_planning
      	Rails.logger.error(("change_head_planning: " + self.inspect).red)
        PlanningConfirmation.change_head_planning(self)
      end

    end
  end
end
