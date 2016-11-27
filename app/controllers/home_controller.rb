class HomeController < ApplicationController

	require "open-uri"
	require 'instagram_feed_by_hashtag'
	require 'RMagick'

	HASHTAG = 'linusfoundthebesther'

	def index
		@old_pics = Picture.order(created_at: :desc)
		p @old_pics #force an eager load

		@new_pics = []
		feed = InstagramFeedByHashtag.feed(HASHTAG, 20) # Make request and store JSON in feed variable
		for picture in feed

			# if there is a new picture, save it to the database and print it out
			if Picture.find_by_pid(picture['id']).nil?
				if !picture['id'].nil? && !picture['display_src'].nil? && !picture['id'].nil?
					p = Picture.new
					p.url = picture['display_src']
					unless picture['caption'].nil?
						p.caption =	picture['caption'][0..200].scrub
					end	
					p.pid = picture['id']
					p.save
					
				 	@new_pics.push(picture)

					begin
						#download picture 
						download_pic(p.url, p.pid)

						#edit picture
						edit_pic(p.pid)

						#print_picture
						system("lpr -P EPSON_PM_400_Series -o PageSize=4x6.Fullbleed " + "#{Rails.root}/public/" + p.pid  + '_print.png')
					rescue
						# do nothing for now, keep going
					end
				end
			end
		end
	end

	def download_pic(link, pid)
		download = open(link)
		IO.copy_stream(download, "#{Rails.root}/public/" + pid  + '.png')
	end

	def edit_pic(pid)
		background = Magick::Image.read("#{Rails.root}/public/background.jpg").first
		img = Magick::Image.read("#{Rails.root}/public/" + pid  + '.png').first

		img = img.resize_to_fill(1260)

		background = background.composite(img, 163, 180, Magick::OverCompositeOp)
		background = background.composite(img, 1614, 180, Magick::OverCompositeOp)
		background.rotate!(90)
		background.write("#{Rails.root}/public/" + pid  + '_print.png')

	end

	def print_pic()
		pid=params[:pid]
		system("lpr -P EPSON_PM_400_Series -o PageSize=4x6.Fullbleed " + "#{Rails.root}/public/" + pid  + '_print.png')
		head :ok
	end
end


