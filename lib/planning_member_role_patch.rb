require_dependency 'member_role'

module PlanningPlugin
  module MemberRolePatch
    def self.included(base)
      base.extend(ClassMethods)

      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable


        after_create :change_kgip_planning
      end
    end

    module ClassMethods
    end

    module InstanceMethods
      def change_kgip_planning
      	kgip_id = Role.kgip_role.try(:id)
        #Rails.logger.error(("create_planning1: " + self.inspect).red)
        if self.role_id == kgip_id
        	PlanningConfirmation.change_kgip_planning(self.member_id)
        end
      end

    end
  end
end
