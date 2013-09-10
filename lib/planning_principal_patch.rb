module PlanningPlugin
  module PrincipalPatch

    def self.included(base)
      base.extend(ClassMethods)

      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable

        scope :not_subordinates, lambda { |manager|
          { 
            :conditions => ["#{Principal.table_name}.id NOT IN (:manager_ids)", {:manager_ids => manager.subordinates.select(:principal_id).map(&:principal_id) + [manager.user_id]}]
          }
        }

      end
    end

    module ClassMethods
    end

    module InstanceMethods
    end

  end
end
