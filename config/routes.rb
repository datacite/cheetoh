Rails.application.routes.draw do
  resources :heartbeat, only: [:index]

  # support login path
  get 'login', :to => 'index#login'

  resources :index, path: '/', only: [:index]
  resources :dois, path: '/id', only: [:show], constraints: { :id => /.+/ }

  # custom routes, as EZID's routes don't follow standard rails pattern
  # we need to add constraints, as the id may contain slashes

  # create identifier
  put 'id/:id', :to => 'dois#create', constraints: { :id => /.+/ }

  # mint identifier
  post 'shoulder/:id', :to => 'dois#mint', constraints: { :id => /.+/ }

  # update identifier
  post 'id/:id', :to => 'dois#update', constraints: { :id => /.+/ }

  # delete identifier
  delete 'id/:id', :to => 'dois#destroy', constraints: { :id => /.+/ }

  root :to => 'index#index'

  # rescue routing errors
  match "*path", to: "application#route_not_found", via: :all
end
