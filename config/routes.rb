Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      post 'auth/login', to: 'auth#login'
      post 'auth/logout', to: 'auth#logout'
      post 'auth/refresh', to: 'auth#refresh'
      get 'auth/verify', to: 'auth#verify'

      resources :members do
        get 'eligibility', on: :member
        post 'recharge', on: :member
        post 'extend_membership', on: :member
        get 'bookings', on: :member, to: 'bookings#my_bookings'
      end

      resources :coaches do
        get 'weekly_schedules', on: :member
        get 'available_slots', on: :member
      end

      resources :coach_schedules do
        collection do
          post 'batch_create_weekly'
          get 'available'
        end
      end

      resources :products

      resources :bookings do
        member do
          post 'cancel'
          post 'force_cancel'
          post 'complete'
          post 'mark_no_show'
        end
      end
    end
  end
end
