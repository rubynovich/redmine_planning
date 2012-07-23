require 'redmine'

Redmine::Plugin.register :redmine_planning do
  name 'Redmine Planning plugin'
  author 'Roman Shipiev'
  description 'Plugin for time managment'
  version '0.0.1'
  url 'https://github.com/rubynovich/redmine_planning'
  author_url 'http://roman.shipiev.me'
  
  permission :view_planning, :estimated_times => [:index, :show]
    
  menu :application_menu, :planning, {:controller => :estimated_times, :action => :index}, :caption => :label_planning, :param => :project_id, :if => Proc.new{User.current.allowed_to?({:controller => :estimated_times, :action => :index}, nil, {:global => true})}
end
