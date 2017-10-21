class HomeController < ApplicationController

	require "open-uri"
	require 'instagram_feed_by_hashtag'
	require 'RMagick'
	require 'aws-sdk'
	require 'mini_magick'
	require 'tempfile'

	HASHTAG = 'sanfrancisco'

	Aws.config.update({
		region: 'us-west-1',
		credentials: Aws::Credentials.new('AKIAJ5LHIKFE2RFTEARQ', 'Umj+fDcsEMJnC02MbeNJaVoSDJDq2oP3hYEzoBlP')
	})

	def print_new_pics
		begin
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
						
					 	@new_pics.push(p)
					
						#download picture, edit pic, and then print pic
						Rails.logger.debug "download pic"
						download_pic(p.url, p.pid)

						Rails.logger.debug "edit pic"
						edit_pic(p.pid)

						Rails.logger.debug "print pic"
						#print_pic_with_pid(p.pid)
					end
				end
			end
		rescue Exception => e 
			Rails.logger.debug "**************** ERROR IN print_new_pics ****************"
			Rails.logger.debug e.message  		
		end
		head :ok
	end

	def index
		begin
			@old_pics = Picture.order(created_at: :desc)
			p @old_pics #force an eager load
		rescue Exception => e 
			Rails.logger.debug "**************** ERROR IN INDEX ****************"
			Rails.logger.debug e.message  		
		end
	end

	def download_pic(link, pid)

		download = open(link)
		
		# Save File to S3
		s3 = Aws::S3::Resource.new
		bucket = s3.bucket('tagprintshare')
		obj = bucket.object(pid  + '.png')      
		obj.upload_file(download)
	end

	def edit_pic(pid)
		begin

			# read the image
			s3 = Aws::S3::Client.new
			resp = s3.get_object(bucket:'tagprintshare', key:pid + '.png')
			tmpimage = Tempfile.new(['image', '.png'])
			IO.copy_stream(resp.body, tmpimage.path)
			img = MiniMagick::Image.open(tmpimage.path)
			img = img.resize("1260")

			#open the background and then merge the img into it
			resp = s3.get_object(bucket:'tagprintshare', key:'background.jpg')
			tmpbackground = Tempfile.new(['background', '.png'])
			IO.copy_stream(resp.body, tmpbackground.path)
			background = MiniMagick::Image.open(tmpbackground.path)

			result = background.composite(img) do |c|
				  c.compose "Over"    # OverCompositeOp
				  c.geometry "+135+220" # copy second_image onto first_image from (20, 20)
			end
			
			result = result.composite(img) do |c|
				  c.compose "Over"    # OverCompositeOp
				  c.geometry "+1581+220" # copy second_image onto first_image from (20, 20)
			end

			#upload image to S3
			s3 = Aws::S3::Resource.new
			bucket = s3.bucket('tagprintshare')
			obj = bucket.object(pid  + '_print.jpg')
			obj.put(body: result.to_blob)

		rescue Exception => e 
			Rails.logger.debug "**************** ERROR IN EDIT PIC ****************"
			Rails.logger.debug e.message  
		end
	end

	def print_pic_with_pid(pid)
		begin
			PhotoMailer.email_photo(pid).deliver
			#system("lpr -P EPSON_PM_400_Series -o PageSize=4x6.Fullbleed " + "#{Rails.root}/public/" + pid  + '_print.jpg')
		rescue Exception => e 
			Rails.logger.debug "**************** ERROR IN PRINT PIC WITH PID****************"
			Rails.logger.debug e.message  
		end
	end

	def print_pic()
		pid=params[:pid]
		begin
			PhotoMailer.email_photo(pid).deliver
			#system("lpr -P EPSON_PM_400_Series -o PageSize=4x6.Fullbleed " + "#{Rails.root}/public/" + pid  + '_print.jpg')
		rescue Exception => e 
			Rails.logger.debug "**************** ERROR IN PRINT PIC ****************"
			Rails.logger.debug e.message  
		end
		head :ok
	end
end


