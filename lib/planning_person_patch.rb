require_dependency 'principal'
require_dependency 'person'

module PlanningPlugin
  module PersonPatch
    def self.included(base)
      base.extend(ClassMethods)
      
      base.send(:include, InstanceMethods)
      
      base.class_eval do
        unloadable

        has_many :planning_confirmations, foreign_key: 'user_id'

      end
    end
      
    module ClassMethods
    end
    
    module InstanceMethods
    end
  end
end
