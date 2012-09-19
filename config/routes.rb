if Rails::VERSION::MAJOR >= 3
  RedmineApp::Application.routes.draw do
    resources :estimated_times do
      collection do
        get :list
      end
    end
    resources :planning_managers    
  end
else
  ActionController::Routing::Routes.draw do |map|
    map.resources :estimated_times
    map.connect 'estimated_time/list', :controller => 'estimated_times', :action => 'list'    
    map.resources :planning_managers
  end
end
