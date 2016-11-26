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
						system("lpr", "#{Rails.root}/public/" + p.pid  + '_print.png')
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
		background = Magick::Image.read("#{Rails.root}/public/background.png").first
		img = Magick::Image.read("#{Rails.root}/public/" + pid  + '.png').first

		# 2x3 is 600, 3x4 is 900, 4x6 is 1200 
		img = img.resize_to_fill(900)

		# merge to two pics
		result = background.composite(img, Magick::CenterGravity, Magick::OverCompositeOp)
		
		# write new pictures
		result.write("#{Rails.root}/public/" + pid  + '.png')
		format_pic_for_double_printing(pid)
	end

	def format_pic_for_double_printing(pid)
		canvas = Magick::Image.new(1800, 1200)
		img = Magick::Image.read("#{Rails.root}/public/" + pid  + '.png').first
		canvas.composite!(img, 0, 0, Magick::OverCompositeOp)
		canvas.composite!(img, 900, 0, Magick::OverCompositeOp)
		canvas.rotate!(90)
		canvas.write("#{Rails.root}/public/" + pid  + '_print.png')
	end

	def print_pic()
		pid=params[:pid]
		system("lpr", "#{Rails.root}/public/" + pid  + '_print.png')
		head :ok
	end
end


