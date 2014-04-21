Rearview::Engine.routes.draw do

  resource :user, only: [:show,:update], :controller => :user

  resources :dashboards, except: [:new,:edit] do
    member do
      get 'errors'
    end
    resources :jobs, only: [:index,:update,:destroy]
    resources :children, only: [:index,:create], controller: :dashboard_children
  end
  get '/dashboards/:dashboard_id/jobs/data' => 'jobs#data'
  get '/dashboards/:dashboard_id/jobs/errors' => 'jobs#errors'

  resources :jobs, except: [:new, :edit] do
    member do
      put 'reset'
    end
    collection do
      get 'validate'
    end
  end

  resource :monitor, only: [:create], :controller => :monitor

  get '/jobs/:id/data' => 'jobs#data'
  get '/jobs/:id/errors' => 'jobs#errors'

  get '/public/templates/*template.hbs', to: redirect('/rearview/templates/%{template}.hbs')

  root :to => 'home#show'

end
