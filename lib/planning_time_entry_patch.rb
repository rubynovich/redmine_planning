module PlanningPlugin
  module TimeEntryPatch
    def self.included(base)
      base.extend(ClassMethods)
      
      base.send(:include, InstanceMethods)
      
      base.class_eval do
        unloadable
        validate :validate_spent_on
      end
    end
      
    module ClassMethods
    end
    
    module InstanceMethods
      def validate_spent_on
        issue = self.issue
        day = self.spent_on
        unless day && 
          (issue.start_date && (issue.start_date <= day))&&
          (issue.due_date && (day <= issue.due_date))&&
          (1.week.ago <= day)&&(day < 1.day.from_now.to_date)
                    
          errors.add :spent_on, :invalid
        end
      end     
    end
  end
end
