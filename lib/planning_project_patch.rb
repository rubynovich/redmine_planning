require_dependency 'project'

module PlanningPlugin
  module ProjectPatch
    def self.included(base)
      base.extend(ClassMethods)

      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable
      end
    end

    module ClassMethods

    end

    module InstanceMethods
      def kgip_members
        self.members.map{|member| member if member.roles.include?(Role.kgip_role)}.compact
      end
      def kgips
        self.kgip_members.map(&:user)
      end
    end
  end
end
