Rails.application.routes.draw do
  resources :heartbeat, only: [:index]

  #resources :index, path: '/', only: [:show, :index], constraints: { id: /.+/, format: false }
  resources :id, only: [:show, :index], constraints: { :id => /.+/ }

  root :to => 'index#index'

  # rescue routing errors
  match "*path", to: "index#routing_error", via: :all
end
