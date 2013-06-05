if Rails::VERSION::MAJOR >= 3
  RedmineApp::Application.routes.draw do
    resources :estimated_times do
      collection do
        get :list
        get :weekend
        get :time_entries
      end
    end
    resources :planning_managers do
      collection do
        get :autocomplete_for_manager
      end
      member do
        get :autocomplete_for_worker
      end
    end
  end
else
  ActionController::Routing::Routes.draw do |map|
    map.resources :estimated_times
    map.connect 'estimated_time/list', :controller => 'estimated_times', :action => 'list'
    map.connect 'estimated_time/weekend', :controller => 'estimated_times', :action => 'weekend'
    map.connect 'estimated_time/time_entries', :controller => 'estimated_times', :action => 'time_entries'
    map.resources :planning_managers
  end
end
