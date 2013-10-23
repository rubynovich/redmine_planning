RedmineApp::Application.routes.draw do
  resources :estimated_times do
    collection do
      get :list
      get :weekend
      get :widget
    end
  end

  resources :planning_preferences do
    collection do
      post :save
    end
  end

  resources :planning_managers do
    collection do
      get :autocomplete_for_manager
    end
    member do
      get :autocomplete_for_subordinate
    end
  end
end
