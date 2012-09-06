module PlanningPlugin
  module TimeEntryPatch
    def self.included(base)
      base.extend(ClassMethods)
      
      base.send(:include, InstanceMethods)
      
      base.class_eval do
        unloadable
        validate :validate_spent_on
        
        named_scope :for_issues, lambda{ |issue_ids|
          if issue_ids.any?
            { :conditions => 
                ["issue_id IN (:issue_ids)",
                  {:issue_ids => issue_ids}]
            }
          end  
        }
        
        named_scope :actual, lambda{ |start_date, due_date|
          if start_date.present? && due_date.present?
            { :conditions => 
                ["spent_on BETWEEN :start_date AND :due_date",
                  {:start_date => start_date, :due_date => due_date}]
            }
          end          
        }
        
        named_scope :for_user, lambda{ |user_id| 
          if user_id.present?
            { :conditions => 
              {:user_id => user_id}
            }            
          end
        }    
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
