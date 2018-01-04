Rails.application.routes.draw do
	#get 'home/'

	resources :home, only: [:index]
	root :to => "home#index"

	post '/', :to =>"home#index"
	post '/home', :to => "home#index"
	
	get '/oauth/connect', :to => "home#connect"
	get '/oauth/callback', :to => "home#callback"
	get '/menu', :to => "home#menu"
	get '/print_new_pics/', :to => "home#print_new_pics"
	get '/print_pic_with_pid/', :to => "home#print_pic_with_pid"
end
