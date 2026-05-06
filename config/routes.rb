Rails.application.routes.draw do
  # OAuth 2.1 for the MCP server (claude.ai remote-connector flow).
  # We control /authorize ourselves; /token and /revoke use the stock Doorkeeper controllers.
  use_doorkeeper do
    skip_controllers :authorizations, :applications, :authorized_applications
  end

  scope module: "oauth" do
    get "/.well-known/oauth-protected-resource", to: "metadata#protected_resource"
    get "/.well-known/oauth-authorization-server", to: "metadata#authorization_server"

    get "/oauth/authorize", to: "authorizations#new", as: :oauth_authorization
    post "/oauth/authorize", to: "authorizations#create"
    delete "/oauth/authorize", to: "authorizations#destroy"

    post "/oauth/register", to: "registrations#create", as: :oauth_registration
  end

  # Account Recovery routes
  get "/account_recovery", to: "account_recoveries#new", as: :new_account_recovery
  post "/account_recovery", to: "account_recoveries#create", as: :create_account_recovery
  get "/account_recovery/verify", to: "account_recoveries#verify", as: :verify_account_recovery
  post "/account_recovery/confirm", to: "account_recoveries#confirm", as: :confirm_account_recovery
  get "/account_recovery/register", to: "account_recoveries#register", as: :register_account_recovery
  post "/account_recovery/register", to: "account_recoveries#register"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", :as => :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Authentication routes
  get "/signup", to: "sessions#new_signup", as: :signup
  post "/signup", to: "sessions#create_signup", as: :create_signup
  post "/signup/verify", to: "sessions#handle_registration", as: :verify_signup
  get "/signin", to: "sessions#new_signin", as: :signin
  post "/signin", to: "sessions#create_signin", as: :create_signin
  post "/signin/verify", to: "sessions#handle_authentication", as: :verify_signin
  delete "/logout", to: "sessions#destroy", as: :logout

  # Dashboard
  get "/dashboard", to: "dashboard#index", as: :dashboard

  # Programs routes with nested exercises
  resources :programs do
    member do
      post :duplicate  # Task Group 2.3: Add duplicate route
      get :export_garmin
    end
    resources :exercises, only: [:new, :create], shallow: true do
      member do
        patch :move
      end
    end
  end

  # Shallow nested exercises routes (show, edit, update and destroy)
  resources :exercises, only: [:show, :edit, :update, :destroy]

  # Personal exercise library
  resources :library_exercises, path: "library", only: [:index, :edit, :update, :destroy]

  # Workouts routes
  resources :workouts, except: [:edit] do
    member do
      patch :mark_complete
      patch :skip
    end
  end

  # Push subscriptions routes
  resources :push_subscriptions, only: [:create, :destroy]

  # Reminders routes
  resources :reminders, only: [:index, :create, :update, :destroy]

  # MCP server (single endpoint per the MCP spec)
  post "/mcp", to: "mcp#handle"

  # Personal access tokens for the JSON API and MCP
  resources :personal_access_tokens, path: "settings/tokens", only: [:index, :new, :create, :destroy]

  # Third-party OAuth apps (e.g. claude.ai) the user has authorized
  resources :connected_apps, path: "settings/connected_apps", only: [:index, :destroy]

  # JSON API
  namespace :api do
    namespace :v1 do
      resources :programs, param: :uuid, only: [:index, :show, :create, :update, :destroy] do
        resources :exercises, only: [:create], param: :id
      end
      resources :exercises, only: [:update, :destroy]
    end
  end

  # Defines the root path route ("/")
  root "home#index"

  if Rails.env.development?
    constraints(->(req) { req.local? }) do
      get "/__dev/signin", to: "dev_sessions#new", as: :dev_signin
      post "/__dev/signin", to: "dev_sessions#create"
    end
  end
end
