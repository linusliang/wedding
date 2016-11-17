class HomeController < ApplicationController

	require "instagram"
	require "awesome_print"
	require 'open-uri'

	CALLBACK_URL = "http://localhost:3000/oauth/callback"
	SCOPE = "public_content"

	def index
	end

	def connect
		redirect_to Instagram.authorize_url(:redirect_uri => CALLBACK_URL, :scope => SCOPE )
	end

	def callback
		response = Instagram.get_access_token(params[:code], :redirect_uri => CALLBACK_URL)
		session[:access_token] = response.access_token
		redirect_to "/menu"
	end

	def menu
		
		@new_pics = []
		@old_pics = []

		@client = Instagram.client(:access_token => session[:access_token])
		#ap @client.tag_recent_media('linusfoundthebesther')

		for media_item in @client.tag_recent_media('linusfoundthebesther')

			# if there is a new picture, save it to the database and
			# also print it out
			if Picture.find_by_pid(media_item.id).nil?
				
				p = Picture.new
				p.url = media_item.images.standard_resolution.url
				p.caption =	media_item.caption.text
				p.pid = media_item.id	
				p.save
				
				@new_pics.push(media_item)

				print_pic(p.url, p.pid)

			# else don't do anything
			#	
			else
				@old_pics.push(media_item)
			end
		end
	end

	def print_pic(link, pic)
		download = open(link)
		IO.copy_stream(download, '~/' + pic  + '.png')
		p "!!!!!!!!!!! Saving " + pic + '.png'
	end
end


