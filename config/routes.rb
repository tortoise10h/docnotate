Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"

  post "settings/editor", to: "settings#update_editor", as: :settings_editor

  resources :documents, only: [:index, :show, :update, :destroy] do
    collection do
      get :open
    end
    member do
      post :open_in_editor
    end
    get "content", to: "document_contents#show", as: :content, format: false
    get "content/*path", to: "document_contents#asset", as: :content_asset, format: false
    resources :comments, only: [:create, :destroy, :update] do
      resource :resolver, only: [:update], controller: "resolver", module: :comments
    end
    resource :version_resolver, only: [:update], controller: "version_resolver", module: :comments
  end
end
