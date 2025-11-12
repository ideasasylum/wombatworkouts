Rails.application.routes.draw do
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
  get "/session/health", to: "sessions#health_check", as: :session_health

  # Dashboard
  get "/dashboard", to: "dashboard#index", as: :dashboard

  # Programs routes with nested exercises
  resources :programs do
    member do
      post :duplicate  # Task Group 2.3: Add duplicate route
    end
    resources :exercises, only: [:new, :create], shallow: true do
      member do
        patch :move
      end
    end
  end

  # Shallow nested exercises routes (show, edit, update and destroy)
  resources :exercises, only: [:show, :edit, :update, :destroy]

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

  # Defines the root path route ("/")
  root "home#index"
end
