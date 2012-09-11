require 'redmine'
require 'dispatcher'
require_dependency 'issue'
require_dependency 'issue_status'
require_dependency 'user'
require_dependency 'time_entry'
require 'planning_issue_patch'
require 'planning_user_patch'
require 'planning_time_entry_patch'

Dispatcher.to_prepare do
  Issue.send(:include, PlanningPlugin::IssuePatch) unless Issue.included_modules.include? PlanningPlugin::IssuePatch
  User.send(:include, PlanningPlugin::UserPatch) unless User.included_modules.include? PlanningPlugin::UserPatch
  TimeEntry.send(:include, PlanningPlugin::TimeEntryPatch) unless TimeEntry.included_modules.include? PlanningPlugin::TimeEntryPatch  
end  

Redmine::Plugin.register :redmine_planning do
  name 'Redmine Planning plugin'
  author 'Roman Shipiev'
  description 'Plugin for time managment'
  version '0.0.4'
  url 'https://github.com/rubynovich/redmine_planning'
  author_url 'http://roman.shipiev.me'
  
  project_module :planning do  
    permission :view_planning, :estimated_times => [:index], :public => true
  end
      
  menu :top_menu, :estimated_times, {:controller => :estimated_times, :action => :index}, :caption => :label_planning, :param => :project_id, :if => Proc.new{User.current.is_planning_manager?}
  
  menu :project_menu, :estimated_times, {:controller => :estimated_times, :action => :index}, :caption => :label_planning, :param => :project_id, :if => Proc.new{User.current.is_planning_manager?}, :require => :member
  
  menu :admin_menu, :planning_manager, 
    {:controller => :planning_managers, :action => :index}, :caption => :label_planning_manager_plural, :html => {:class => :users}
end

