class HomeController < ApplicationController

	require "instagram"

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


		p "ASDFASDFASDFASDFASDFASDFASDFASDFASDFASDFASDAS"
		p "ASDFASDFASDFASDFASDFASDFASDFASDFASDFASDFASDAS"
		p "ASDFASDFASDFASDFASDFASDFASDFASDFASDFASDFASDAS"
		p "ASDFASDFASDFASDFASDFASDFASDFASDFASDFASDFASDAS"
		p "ASDFASDFASDFASDFASDFASDFASDFASDFASDFASDFASDAS"
		p "ASDFASDFASDFASDFASDFASDFASDFASDFASDFASDFASDAS"
		p "ASDFASDFASDFASDFASDFASDFASDFASDFASDFASDFASDAS"
		p "ASDFASDFASDFASDFASDFASDFASDFASDFASDFASDFASDAS"
		p ""
		p ""
		p ""
		pp @client.tag_recent_media('linusfoundthebesther').to_s
		p ""
		p ""
		p ""
		p "ASDFASDFASDFASDFASDFASDFASDFASDFASDFASDFASDAS"
		p "ASDFASDFASDFASDFASDFASDFASDFASDFASDFASDFASDAS"
		p "ASDFASDFASDFASDFASDFASDFASDFASDFASDFASDFASDAS"
		p "ASDFASDFASDFASDFASDFASDFASDFASDFASDFASDFASDAS"
		p "ASDFASDFASDFASDFASDFASDFASDFASDFASDFASDFASDAS"
		p "ASDFASDFASDFASDFASDFASDFASDFASDFASDFASDFASDAS"
		p "ASDFASDFASDFASDFASDFASDFASDFASDFASDFASDFASDAS"
		p "ASDFASDFASDFASDFASDFASDFASDFASDFASDFASDFASDAS"


		for media_item in @client.tag_recent_media('linusfoundthebesther')

			if Picture.find_by_pid(media_item.id).nil?
				
				p = Picture.new
				p.url = media_item.images.standard_resolution.url
				p.caption =	media_item.caption.text
				p.pid = media_item.id	
				p.save
				
				@new_pics.push(media_item)
			else
				@old_pics.push(media_item)
			end
		end
	end

end


