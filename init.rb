require 'redmine'

Redmine::Plugin.register :redmine_planning do
  name 'Redmine Planning plugin'
  author 'Roman Shipiev'
  description 'Plugin for time managment'
  version '0.0.2'
  url 'https://github.com/rubynovich/redmine_planning'
  author_url 'http://roman.shipiev.me'
  
  permission :view_planning, :estimated_times => [:index, :edit, :new, :create, :update]
  permission :change_current_user, {}
  
  project_module :estimated_times do
    permission :view_planning, :estimated_times => [:index, :edit, :new, :create, :update]
    permission :change_current_user, {}    
  end
  
  menu :application_menu, :estimated_times, {:controller => :estimated_times, :action => :index}, :caption => :label_planning, :param => :project_id, :if => Proc.new{User.current.allowed_to?({:controller => :estimated_times, :action => :index}, nil, {:global => true})}
  
  menu :project_menu, :estimated_times, {:controller => :estimated_times, :action => :index}, :caption => :label_planning, :param => :project_id, :if => Proc.new{User.current.allowed_to?({:controller => :estimated_times, :action => :index}, nil, {:global => true})}, :require => :member
end
