Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      post "auth/login", to: "auth#login"
      get "auth/me", to: "auth#me"
      delete "auth/logout", to: "auth#logout"

      get :health, to: "health#index"

      resources :users, only: [:index, :show, :create, :update, :destroy] do
        collection do
          get :tenant
          get :admin
          get :owner
        end
      end

      resources :properties do
        member do
          get :tenants
          get :export_tenants
          get :units
          get :export_units
          get :maintenance
          get :export_maintenance
        end
      end

      resources :units, only: [:index, :show, :create, :update, :destroy] do
        collection do
          get "property/:property_id", action: :index_by_property
        end
      end

      resources :maintenance_requests,
                only: [:index, :show, :create, :update, :destroy] do
        collection do
          get :export
        end
      end

      resources :financial_transactions,
                only: [:index, :show, :create, :update, :destroy] do
        collection do
          get :dashboard
          get :export
        end
      end

      resources :payments, only: [:index, :show, :create, :update, :destroy] do
        member do
          post :push_invoice
        end
      end

      resources :communications, only: [:index, :show, :create, :update, :destroy]
      resources :log_activities, only: [:index, :show]

      namespace :webhooks do
        namespace :xendit do
          post :invoice_paid, to: "invoices#paid"
        end
      end
    end
  end
end
