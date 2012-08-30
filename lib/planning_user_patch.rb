module PlanningPlugin
  module UserPatch
    def self.included(base)
      base.extend(ClassMethods)
      
      base.send(:include, InstanceMethods)
      
      base.class_eval do
        unloadable
        
        named_scope :not_planning_managers, lambda {
        { :conditions => ["#{User.table_name}.id NOT IN (SELECT #{PlanningManager.table_name}.user_id FROM #{PlanningManager.table_name})"] }
        }
      end
    end
      
    module ClassMethods
    end
    
    module InstanceMethods
      def workers
        if manager = PlanningManager.find(self.id)
          User.find(YAML.load(manager.workers))
        else
          []
        end
      end
      
      def is_planning_manager?
        PlanningManager.find_by_user_id(self.id).present?
      end        
    end
  end
end
