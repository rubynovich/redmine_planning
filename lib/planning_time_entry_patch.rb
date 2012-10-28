require_dependency 'time_entry'

module PlanningPlugin
  module TimeEntryPatch
    def self.included(base)
      base.extend(ClassMethods)
      
      base.send(:include, InstanceMethods)
      
      base.class_eval do
        unloadable
        
        include EstimatedTimesHelper        
        
        validate :validate_spent_on
        validates_presence_of :comments
        
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
        unless can_change_spent?(issue, day)     
          errors.add :spent_on, :invalid
        end
      end     
    end    
  end
end
