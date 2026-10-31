# MCP over Streamable HTTP. StreamableHTTPTransport is a Rack app, so it can
# be mounted directly: POST carries JSON-RPC messages, GET opens an SSE
# stream, DELETE terminates the session (see docs/mcp-server.md). The server
# assembly lives in app/mcp/docnotate_server.rb; routes are loaded after
# initialization, so its tool classes are autoloadable here (they would not be
# inside config/initializers). The transport keeps session state in memory,
# which is fine for our single Puma process.
DocnotateServerTransport = MCP::Server::Transports::StreamableHTTPTransport.new(DocnotateServer)

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
  post "settings/theme", to: "settings#update_theme", as: :settings_theme

  # MCP endpoint for coding agents (see DocnotateServerTransport above)
  mount DocnotateServerTransport => "/mcp", as: :mcp

  resource :filesystem, only: [:show], controller: "filesystem" do
    get :nodes
  end

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
