# frozen_string_literal: true

require 'sidekiq/web'
require 'sidekiq/cron/web'

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check
  mount Sidekiq::Web => '/sidekiq'

  namespace :api do
    namespace :v1 do
      devise_for :users, path: '', path_names: {
        sign_in: 'login',
        sign_out: 'logout',
        registration: 'signup'
      }, controllers: {
        sessions: 'api/v1/sessions',
        registrations: 'api/v1/registrations',
        passwords: 'api/v1/passwords'
      }

      # Authentication routes
      get 'me', to: 'users#me'

      resources :tasks
      resources :profiles, only: %i[show update] do
        member do
          patch :complete_onboarding
        end
      end
      resources :smart_goals
      resource :journal, only: %i[show] do
        resources :journal_entries, only: %i[index show create update destroy]
      end
      resources :tickets, only: %i[create show]
      post 'ai/proxy', to: 'ai#proxy'
      post 'ai/usage', to: 'ai#usage'
      post 'ai/suggested_tasks', to: 'ai#suggested_tasks'

      # Job status endpoint
      get 'jobs/:id', to: 'job_status#show'
      resources :device_tokens, only: %i[create destroy]
      resource :notification_preferences, only: %i[show update]

      resources :habits, only: %i[create]
      resources :habit_completions, only: %i[create]
      resources :notification_schedules, only: %i[create]

      get 'onboarding/resume', to: 'onboarding#resume'
      namespace :onboarding do
        namespace :discovery do
          resources :sessions, only: %i[create]
          resources :messages, only: %i[create]
        end
        post 'habits/suggest', to: 'habits#suggest'
      end
    end
  end
end
