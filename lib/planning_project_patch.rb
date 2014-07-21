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
        #self.members.map{|member| member if member.roles.include?(Role.kgip_role)}.compact
        self.members.joins(:roles).where(["roles.id = ?", Setting[:plugin_redmine_planning][:kgip_role_id].to_i])
      end
      def kgips
        self.kgip_members.map(&:user)
      end

      def kgip_ids
        self.kgip_members.map(&:user_id)
      end

    end
  end
end
