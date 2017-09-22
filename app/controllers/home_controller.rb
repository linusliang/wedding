class HomeController < ApplicationController

	require "open-uri"
	require 'instagram_feed_by_hashtag'
	require 'RMagick'

	HASHTAG = 'tagprintshare'

	def index	
		@old_pics = Picture.order(created_at: :desc)
		p @old_pics #force an eager load

		@new_pics = []
		begin
			feed = InstagramFeedByHashtag.feed(HASHTAG, 20) # Make request and store JSON in feed variable
		rescue
			# do nothing for now, keep going
		end

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
						#download picture, edit pic, and then print pic
						download_pic(p.url, p.pid)
						edit_pic(p.pid)
						sleep(1.seconds)
						print_pic_with_pid(p.pid)
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
		# read the image
		img = Magick::Image.read("#{Rails.root}/public/" + pid  + '.png').first
		img = img.resize_to_fill(1260)

		# open the background and then merge the img into it
		background = Magick::Image.read("#{Rails.root}/public/background.jpg").first
		background = background.composite(img, 135, 220, Magick::OverCompositeOp)
		background = background.composite(img, 1581, 220, Magick::OverCompositeOp)
		background.write("#{Rails.root}/public/" + pid  + '_print.jpg')
	end

	def print_pic_with_pid(pid)
		#system("lpr -P EPSON_PM_400_Series -o PageSize=4x6.Fullbleed " + "#{Rails.root}/public/" + pid  + '_print.jpg')
		PhotoMailer.email_photo(pid).deliver
	end

	def print_pic()
		pid=params[:pid]
		PhotoMailer.email_photo(pid).deliver
		#system("lpr -P EPSON_PM_400_Series -o PageSize=4x6.Fullbleed " + "#{Rails.root}/public/" + pid  + '_print.jpg')
		head :ok
	end
end


