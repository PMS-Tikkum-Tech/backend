Rails.application.routes.draw do
  # API v1 routes
  namespace :api do
    namespace :v1 do
      # Authentication & User Management endpoints (unified in AuthController)
      namespace :auth do
        post :login
        get :me
        delete :logout
      end

      # User CRUD endpoints (handled by AuthController)
      resources :users, only: %i[index show create update destroy], controller: 'auth'

      # Health check
      get 'health', to: 'health#index'
    end
  end

  # Reveal health status on /up
  get 'up', to: 'rails/health#show', as: :rails_health_check
end
