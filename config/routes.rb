Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  resource :setup, only: %i[new create], controller: "setup"
  post "sync" => "syncs#create", as: :sync_now

  resources :leagues, only: :show do
    member do
      get :waivers
      get :trades
      get :trade_log
      get :ammo
    end
  end

  root "dashboard#show"
end
