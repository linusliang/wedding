Rails.application.routes.draw do
  #get 'home/'
  
  root :to => "home#index"

  get '/oauth/connect', :to => "home#connect"
  get '/oauth/callback', :to => "home#callback"
  get '/menu', :to => "home#menu"

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
