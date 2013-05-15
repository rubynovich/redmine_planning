if Rails::VERSION::MAJOR >= 3
  RedmineApp::Application.routes.draw do
    resources :estimated_times do
      collection do
        get :list
        get :weekend
#        get :list_with_spent
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
#    map.connect 'estimated_time/list_with_spent', :controller => 'estimated_times', :action => 'list_with_spent'
    map.resources :planning_managers
  end
end
