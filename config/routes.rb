RedmineApp::Application.routes.draw do
  resources :estimated_times do
    collection do
      get :list
      get :weekend
      get :widget
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
