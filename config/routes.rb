RedmineApp::Application.routes.draw do
  resources :estimated_times do
    collection do
      get :list
      get :weekend
      get :widget
      get :confirm_time
    end
  end

  resources :planning_preferences do
    collection do
      post :save
      post :drop
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

  resources :planning_confirmations do
    collection do
      post :create_confirmation, defaults: {format: 'js'}
    end
    member do
      put :update_confirmer, defaults: {format: 'js'}
      post :create_comment, defaults: {format: 'js'}
    end
  end

end
