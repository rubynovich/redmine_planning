require_dependency 'role'

module PlanningPlugin
  module RolePatch
    def self.included(base)
      base.extend(ClassMethods)

      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable
      end
    end

    module ClassMethods
      def kgip_role
        Role.where(id: Setting[:plugin_redmine_planning][:kgip_role_id].to_i).first
      end
    end

    module InstanceMethods
    end
  end
end
