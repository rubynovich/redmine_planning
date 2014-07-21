require 'redmine'

Redmine::Plugin.register :redmine_planning do
  name 'Planning'
  author 'Roman Shipiev'
  description 'Scheduling time on issues'
  version '0.1.0'
  url 'https://bitbucket.org/rubynovich/redmine_planning'
  author_url 'http://roman.shipiev.me'

  settings :partial => 'estimated_times/settings', :default => {
    :work_hours_per_day => 8,
    :min_unfilled_percent => 75
  }

  project_module :planning do
    # permission :view_planning, :estimated_times => [:index], :public => true
  end

  Redmine::MenuManager.map :top_menu do |menu| 

    parent = menu.exists?(:workflow) ? :workflow : :top_menu
    menu.push(:estimated_times, {:controller => :estimated_times, :action => :index}, 
              { :parent => parent,
                :caption => :label_planning, 
                :param => :project_id, 
                :if => Proc.new{ User.current.is_planning_manager? }
              })

  end

  # menu :project_menu, :estimated_times, 
  #   {:controller => :estimated_times, :action => :index}, 
  #   :caption => :label_planning, 
  #   :param => :project_id, 
  #   :if => Proc.new{User.current.is_planning_manager?}, :require => :member

  menu :admin_menu, :planning_manager,
    {:controller => :planning_managers, :action => :index}, 
    :caption => :label_planning_manager_plural, 
    :html => {:class => :users}

end

Rails.configuration.to_prepare do


  require_dependency '../app/models/planning_confirmation'

  begin
    Sidekiq.hook_rails!

    Sidekiq.remove_delay!

  rescue
  end

  [:issue, :issues_controller, :member_role, :people_controller, :department, :user, :principal, :time_entry, :timelog_helper, :project, :role].each do |cl|
    require "planning_#{cl}_patch"
  end

  [
   [Issue, PlanningPlugin::IssuePatch],
   [Project, PlanningPlugin::ProjectPatch],
   [IssuesController, PlanningPlugin::IssuesControllerPatch],
   [User, PlanningPlugin::UserPatch],
   [Role, PlanningPlugin::RolePatch],
   [PeopleController, PlanningPlugin::PeopleControllerPatch],
   [MemberRole, PlanningPlugin::MemberRolePatch],
   [Department, PlanningPlugin::DepartmentPatch],
   [Principal, PlanningPlugin::PrincipalPatch],
   [TimeEntry, PlanningPlugin::TimeEntryPatch],
   [TimelogHelper, PlanningPlugin::TimelogHelperPatch]
  ].each do |cl, patch|
    cl.send(:include, patch) unless cl.included_modules.include? patch
  end
end
