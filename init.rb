require 'redmine'

Redmine::Plugin.register :redmine_planning do
  name 'Planning'
  author 'Roman Shipiev'
  description 'Scheduling time on issues'
  version '0.0.6'
  url 'https://bitbucket.org/rubynovich/redmine_planning'
  author_url 'http://roman.shipiev.me'

  project_module :planning do
#    permission :view_planning, :estimated_times => [:index], :public => true
  end

  menu :top_menu, :estimated_times, {:controller => :estimated_times, :action => :index}, :caption => :label_planning, :param => :project_id, :if => Proc.new{User.current.is_planning_manager?}

  menu :project_menu, :estimated_times, {:controller => :estimated_times, :action => :index}, :caption => :label_planning, :param => :project_id, :if => Proc.new{User.current.is_planning_manager?}, :require => :member

  menu :admin_menu, :planning_manager,
    {:controller => :planning_managers, :action => :index}, :caption => :label_planning_manager_plural, :html => {:class => :users}
end

if Rails::VERSION::MAJOR < 3
  require 'dispatcher'
  object_to_prepare = Dispatcher
else
  object_to_prepare = Rails.configuration
end

object_to_prepare.to_prepare do
  [:issue, :user, :time_entry, :timelog_helper].each do |cl|
    require "planning_#{cl}_patch"
  end

  [ [Issue, PlanningPlugin::IssuePatch], [User, PlanningPlugin::UserPatch],
    [TimeEntry, PlanningPlugin::TimeEntryPatch], [TimelogHelper, PlanningPlugin::TimelogHelperPatch]
  ].each do |cl, patch|
    cl.send(:include, patch) unless cl.included_modules.include? patch
  end
end
