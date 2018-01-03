Rails.application.routes.draw do
	#get 'home/'

	resources :home, only: [:index]
	root :to => "home#index"
	post '/', :to =>"home#index"

	get '/oauth/connect', :to => "home#connect"
	get '/oauth/callback', :to => "home#callback"
	get '/menu', :to => "home#menu"
	get '/home/print_pic/:pid', :to => "home#print_pic", pid: :pid
	get '/print_new_pics/', :to => "home#print_new_pics"
end
