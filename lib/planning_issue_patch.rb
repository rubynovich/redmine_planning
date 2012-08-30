module PlanningPlugin
  module IssuePatch
    def self.included(base)
      base.extend(ClassMethods)
      
      base.send(:include, InstanceMethods)
      
      base.class_eval do
        unloadable
      
        named_scope :in_project, lambda { |project|
          if project.present?
            { :conditions => 
              {
                :project_id => project.id
              }
            }
          end
        }

        named_scope :actual, lambda { |start_date, due_date|
          if start_date.present? && due_date.present?
            { :conditions => 
                ["#{IssueStatus.table_name}.is_closed = :is_closed OR #{Issue.table_name}.start_date BETWEEN :start_date AND :due_date OR #{Issue.table_name}.due_date BETWEEN :start_date AND :due_date", {:is_closed => false, :start_date => start_date, :due_date => due_date}],
              :include => :status
            }
          else
            { :conditions => 
                ["#{IssueStatus.table_name}.is_closed = :is_closed",
                  {:is_closed => false}],
              :include => :status
            }            
          end
        }                  
      end
    end
      
    module ClassMethods
    end
    
    module InstanceMethods
    end
  end
end
