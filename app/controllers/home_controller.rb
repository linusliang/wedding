class HomeController < ApplicationController

	require "open-uri"
	require 'instagram_feed_by_hashtag'
	require 'RMagick'
	require 'aws-sdk'

	HASHTAG = 'tagprintshare'

	Aws.config.update({
		region: 'us-west-1',
		credentials: Aws::Credentials.new('AKIAJ5LHIKFE2RFTEARQ', 'Umj+fDcsEMJnC02MbeNJaVoSDJDq2oP3hYEzoBlP')
	})

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
						Rails.logger.debug "download pic"
						download_pic(p.url, p.pid)
						sleep(1.seconds)

						Rails.logger.debug "edit pic"
						edit_pic(p.pid)
						sleep(1.seconds)

						Rails.logger.debug "print pic"
						#print_pic_with_pid(p.pid)
					rescue
						# do nothing for now, keep going
					end
				end
			end
		end
	end

	def download_pic(link, pid)

		download = open(link)
		
		# Save File to S3
		s3 = Aws::S3::Resource.new
		bucket = s3.bucket('tagprintshare')
		obj = bucket.object(pid  + '.png')      
		obj.upload_file(download)

		#IO.copy_stream(download, "#{Rails.root}/public/" + pid  + '.png')
	end

	def edit_pic(pid)

		begin
			retries ||= 0
  			Rails.logger.debug "try ##{ retries }"

			# read the image
			Rails.logger.debug "read the image"

			#s3 = Aws::S3::Client.new
			#resp = s3.get_object(bucket:'tagprintshare', key: pid  + '.png')
			#Rails.logger.debug "!!!!!" + resp.body.read
			#img = Magick::Image.read(resp.body.read).first
			#img = img.resize_to_fill(1260)

			img = Magick::Image.read("https://s3-us-west-1.amazonaws.com/tagprintshare/" + pid  + '.png').first
			img = img.resize_to_fill(1260)

			#open the background and then merge the img into it
			Rails.logger.debug "open the background and then merge the img into it"
			background = Magick::Image.read("https://s3-us-west-1.amazonaws.com/tagprintshare/background.jpg").first
			background = background.composite(img, 135, 220, Magick::OverCompositeOp)
			background = background.composite(img, 1581, 220, Magick::OverCompositeOp)
			#background.write(#{Rails.root}/public/" + pid  + '_print.png')

			# upload image to S3
			Rails.logger.debug "upload image to S3"
			s3 = Aws::S3::Resource.new
			bucket = s3.bucket('tagprintshare')
			obj = bucket.object(pid  + '_print.jpg')
			obj.put(body: background.to_blob)
			Rails.logger.debug "DONE!!!!!!!!!!!!!!!!!!!!!!"

		rescue Exception => e 
			retry if (retries += 1) < 5
			Rails.logger.debug "ERROR!!!!!!!!!!!!!!!!!!!!!!"
			Rails.logger.debug e.message  
		end




	end

	def print_pic_with_pid(pid)
		#PhotoMailer.email_photo(pid).deliver
		#system("lpr -P EPSON_PM_400_Series -o PageSize=4x6.Fullbleed " + "#{Rails.root}/public/" + pid  + '_print.jpg')
	end

	def print_pic()
		pid=params[:pid]
		#PhotoMailer.email_photo(pid).deliver

		#system("lpr -P EPSON_PM_400_Series -o PageSize=4x6.Fullbleed " + "#{Rails.root}/public/" + pid  + '_print.jpg')
		head :ok
	end
end


