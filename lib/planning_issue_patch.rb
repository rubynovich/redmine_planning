require_dependency 'issue'
require_dependency 'issue_status'

module PlanningPlugin
  module IssuePatch
    def self.included(base)
      base.extend(ClassMethods)
      
      base.send(:include, InstanceMethods)
      
      base.class_eval do
        unloadable
        
        if Rails::VERSION::MAJOR >= 3
          scope :in_project, lambda { |project|
            if project.present?
              { :conditions => 
                {
                  :project_id => project.id
                }
              }
            end
          }

          scope :actual, lambda { |start_date, due_date|
            if start_date.present? && due_date.present?
              { :conditions => 
                  ["#{IssueStatus.table_name}.is_closed = :is_closed OR #{Issue.table_name}.start_date BETWEEN :start_date AND :due_date OR #{Issue.table_name}.due_date BETWEEN :start_date AND :due_date OR #{Issue.table_name}.start_date <= :start_date AND #{Issue.table_name}.due_date >= :due_date", {:is_closed => false, :start_date => start_date, :due_date => due_date}],
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
          
          scope :exclude_closed, lambda{ |exclude|        
            if exclude.present?
              { :conditions => 
                  ["#{IssueStatus.table_name}.is_closed = :is_closed",
                    {:is_closed => false}],
                :include => :status
              }
            end
          }
          
          scope :exclude_not_planned, lambda{ |exclude, current_date|
            if exclude.present?
              { :conditions => ["#{Issue.table_name}.id IN (SELECT #{EstimatedTime.table_name}.issue_id FROM #{EstimatedTime.table_name} WHERE #{EstimatedTime.table_name}.plan_on BETWEEN :start_date AND :due_date)", {:start_date => current_date, :due_date => current_date + 6.days}]
              }
            end
          }
          
          scope :exclude_overdue, lambda{ |exclude, current_date|
            if exclude.present?
              { :conditions => 
                ["due_date > ?", current_date]
              }          
            end          
          }
        else
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
                  ["#{IssueStatus.table_name}.is_closed = :is_closed OR #{Issue.table_name}.start_date BETWEEN :start_date AND :due_date OR #{Issue.table_name}.due_date BETWEEN :start_date AND :due_date OR #{Issue.table_name}.start_date <= :start_date AND #{Issue.table_name}.due_date >= :due_date", {:is_closed => false, :start_date => start_date, :due_date => due_date}],
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
          
          named_scope :exclude_closed, lambda{ |exclude|        
            if exclude.present?
              { :conditions => 
                  ["#{IssueStatus.table_name}.is_closed = :is_closed",
                    {:is_closed => false}],
                :include => :status
              }
            end
          }
          
          named_scope :exclude_not_planned, lambda{ |exclude, current_date|
            if exclude.present?
              { :conditions => ["#{Issue.table_name}.id IN (SELECT #{EstimatedTime.table_name}.issue_id FROM #{EstimatedTime.table_name} WHERE #{EstimatedTime.table_name}.plan_on BETWEEN :start_date AND :due_date)", {:start_date => current_date, :due_date => current_date + 6.days}]
              }
            end
          }
          
          named_scope :exclude_overdue, lambda{ |exclude, current_date|
            if exclude.present?
              { :conditions => 
                ["due_date > ?", current_date]
              }          
            end          
          }
        end        
      end
    end
      
    module ClassMethods
    end
    
    module InstanceMethods
    end
  end
end
