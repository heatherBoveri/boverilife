Rails.application.routes.draw do
  root to: 'trips#index'

  get '/trips/ratings', to: 'trips#ratings'
  get '/trips/years', to: 'trips#years'
  get '/trips/lifetime', to: 'trips#lifetime'
  get '/trips/categories', to: 'trips#categories'
  get '/trips/retirement', to: 'trips#retirement'
  get '/trips/kids', to: 'trips#kids'
  get '/trips/ignored', to: 'trips#ignored'

  resources :trips
end
