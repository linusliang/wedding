class HomeController < ApplicationController

	require "awesome_print"
	require "open-uri"
	require 'instagram_feed_by_hashtag'
	require 'RMagick'

	# KC-18IL / 2.1" x 3.4"

	HASHTAG = 'linusfoundthebesther'

	def index
		@new_pics = []
		@old_pics = []

		@client = Instagram.client(:access_token => session[:access_token])
		#ap @client.tag_recent_media('linusfoundthebesther')

		feed = InstagramFeedByHashtag.feed(HASHTAG, 20) # Make request and store JSON in feed variable
		#ap feed

		for picture in feed

			# if there is a new picture, save it to the database and
			# also print it out
			if Picture.find_by_pid(picture['id']).nil?
				
				p = Picture.new
				p.url = picture['display_src']
				unless picture['caption'].nil?
					p.caption =	picture['caption'][0..200].scrub
				end	
				p.pid = picture['id']
				p.save
				
			 	@new_pics.push(picture)

				#download picture 
				download_pic(p.url, p.pid)

				#edit picture
				edit_pic(p.pid)

				#print_picture
				#print_pic(p.pid)

			# else don't do anything
			#	
			else
			 	@old_pics.push(picture)
			end
		end
	end

	def download_pic(link, pid)
		download = open(link)
		IO.copy_stream(download, "#{Rails.root}/public/" + pid  + '.png')
	end

	def edit_pic(pid)
		background = Magick::Image.read("#{Rails.root}/public/background.png").first
		img = Magick::Image.read("#{Rails.root}/public/" + pid  + '.png').first
		img = img.resize_to_fill(600)
		result = background.composite(img, Magick::CenterGravity, Magick::OverCompositeOp)
		result.write("#{Rails.root}/public/" + pid  + '.png')
	end

	def print_pic(pid)
		system("lpr", "#{Rails.root}/public/" + pid  + '.png')
	end
end


