class HomeController < ApplicationController

	require "open-uri"
	require 'RMagick'
	require 'aws-sdk'
	require 'mini_magick'
	require 'tempfile'

	$hashtag = '#BecksWildOne'
	$ipbucket  = 'instaprinter3'
	$ipbackground = 'ip3_background.jpg'
                     
	Aws.config.update({
		region: 'us-west-1',
		credentials: Aws::Credentials.new('AKIAJ5LHIKFE2RFTEARQ', 'Umj+fDcsEMJnC02MbeNJaVoSDJDq2oP3hYEzoBlP')
	})

	def scrape_instagram(hashtag, how_many)
	    require 'net/http'
	    url_raw = 'https://www.instagram.com/explore/tags/'+ hashtag +'/?__a=1'
	    url = URI.parse("#{url_raw}")
	    begin
	      resp = Net::HTTP.get(url)
	    rescue Errno::ETIMEDOUT, Errno::EINVAL, Errno::ECONNRESET, EOFError, Net::HTTPBadResponse => e
	      resp = false
	    end
	    unless resp == false
	      result = []
	      parsed_json = JSON.parse(resp)
	      #puts JSON.pretty_generate(parsed_json) # save for debugging, good viewer at http://jsonviewer.stack.hu/
	      for i in 0..(how_many - 1)
	        result << parsed_json['graphql']['hashtag']['edge_hashtag_to_media']['edges'][i]['node'] unless parsed_json['graphql']['hashtag']['edge_hashtag_to_media']['edges'][i].nil?
	      end
	    end
	    result
	end

	def print_new_pics
		begin
			@new_pics = []
			feed = scrape_instagram($hashtag, 20) # Make request and store JSON in feed variable

			for picture in feed
				# if there is a new picture, save it to the database and print it out
				if Picture.find_by_pid(picture['id']).nil?
					if !picture['id'].nil? && !picture['display_url'].nil?
						p = Picture.new
						p.url = picture['display_url']
						p.time_taken = picture['taken_at_timestamp']

						unless picture['edge_media_to_caption']['edges'][0]['node']['text'].nil?
							p.caption =	picture['edge_media_to_caption']['edges'][0]['node']['text'][0..200].scrub
							if (p.caption.length > 199)
								p.caption = p.caption + " ..."
							end	
						end	
						p.pid = picture['id']
						p.save
						
						# save picture into the database
					 	@new_pics.push(p)

						#download picture, edit pic, and then print pic
						Rails.logger.debug "download pic"
						download_pic(p.url, p.pid)

						Rails.logger.debug "edit pic"
						edit_pic(p.pid)
						#edit_pic_username_caption(p.pid, picture, p.caption)

						if params[:print_flag] != "false"
							Rails.logger.debug "printing pic " + p.pid 
							print_pic_with_pid(p.pid)
						end
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

		# check to see if we enable admin mode
		if params[:admin]=="on"
			session[:admin] = true
		end

		begin
			# load the pictures
			@old_pics = Picture.order(time_taken: :desc).paginate(page: params[:page], per_page: 15)
			p @old_pics #force an eager load

			# let user turn script on/off
			@pid = (`pgrep -f refresh_script.rb`)
			if params[:switch] == "on" && @pid == ""
				#Rails.logger.debug "turning process on"
				output = (`nohup ruby /var/app/current/refresh_script.rb > /dev/null &`)
				@pid = (`pgrep -f refresh_script.rb`)
			elsif params[:switch] == "off"	&& @pid != ""
				#Rails.logger.debug "killing PID:" + @pid
				Process.kill('KILL', @pid.to_i)	
				@pid = ""
			end

		rescue Exception => e 
			Rails.logger.debug "**************** ERROR IN INDEX ****************"
			Rails.logger.debug e.message  		
		end
	end

	def get_username(picture)

		require 'net/http'
		url_raw = 'https://www.instagram.com/p/'+ picture['shortcode'] +'/?__a=1'
		url = URI.parse("#{url_raw}")
		begin
		  resp = Net::HTTP.get(url)
		rescue Errno::ETIMEDOUT, Errno::EINVAL, Errno::ECONNRESET, EOFError, Net::HTTPBadResponse => e
		  resp = false
		end

		unless resp == false
		  result = []
		  parsed_json = JSON.parse(resp)
		  username = parsed_json['graphql']['shortcode_media']['owner']['username']
		end
		username
	end

	def download_pic(link, pid)

		download = open(link)
		
		# Save File to S3
		s3 = Aws::S3::Resource.new
		bucket = s3.bucket($ipbucket)
		obj = bucket.object(pid  + '.png')      
		obj.upload_file(download)
	end

	def edit_pic(pid)
		begin

			# read the image
			s3 = Aws::S3::Client.new
			resp = s3.get_object(bucket:$ipbucket, key:pid + '.png')
			tmpimage = Tempfile.new(['image', '.png'])
			IO.copy_stream(resp.body, tmpimage.path)
			img = MiniMagick::Image.open(tmpimage.path)
			img = img.resize("1260x1260")
			
			#open the background and then merge the img into it
			resp = s3.get_object(bucket:'iptemplates', key:$ipbackground)
			tmpbackground = Tempfile.new(['background', '.png'])
			IO.copy_stream(resp.body, tmpbackground.path)
			background = MiniMagick::Image.open(tmpbackground.path)

			result = background.composite(img) do |c|
				 c.compose "Over"    # OverCompositeOp
				 if img[:width] == 1008
				 	c.geometry "+261+220" # copy second_image onto first_image from (20, 20)				 	
				 else
				 	c.geometry "+135+220" # copy second_image onto first_image from (20, 20)
				 end
			end
			
			result = result.composite(img) do |c|
				  c.compose "Over"    # OverCompositeOp
				  if img[:width] == 1008
					  c.geometry "+1682+220" # copy second_image onto first_image from (20, 20)
				  else
					  c.geometry "+1556+220" # copy second_image onto first_image from (20, 20)
				  end
			end

			#upload image to S3
			s3 = Aws::S3::Resource.new
			bucket = s3.bucket($ipbucket)
			obj = bucket.object(pid  + '_print.jpg')
			obj.put(body: result.to_blob)

		rescue Exception => e 
			Rails.logger.debug "**************** ERROR IN EDIT PIC ****************"
			Rails.logger.debug e.message  
		end
	end

	def wrap(s, width=78)
	  s.gsub(/(.{1,#{width}})(\s+|\Z)/, "\\1\n")
	end

	def edit_pic_username_caption(pid, picture, caption)
		begin

			if !picture.nil?
				username = get_username(picture)
			end 

			# read the image
			s3 = Aws::S3::Client.new
			resp = s3.get_object(bucket:$ipbucket, key:pid + '.png')
			tmpimage = Tempfile.new(['image', '.png'])
			IO.copy_stream(resp.body, tmpimage.path)
			img = MiniMagick::Image.open(tmpimage.path)
			img = img.resize("1260x1260")
			
			#open the background and then merge the img into it
			resp = s3.get_object(bucket:'iptemplates', key:$ipbackground)
			tmpbackground = Tempfile.new(['background', '.png'])
			IO.copy_stream(resp.body, tmpbackground.path)
			background = MiniMagick::Image.open(tmpbackground.path)

			# create the caption
	      	caption.scrub 
	      	caption = " " * (username.length * 1.8) + caption
			newcaption = wrap(caption, 50)

			offset = 660 + (newcaption.length / 50) * 25

			#now add the username to the background
			font = "#{Rails.root}/public/Arial_Bold.ttf"
			background =  background.combine_options do |i|
		        i.font font
		        i.gravity "West"
		        i.pointsize 50
		        i.draw "text 168,627 '#{username}'"
		        i.draw "text 1580,627 '#{username}'"
	      	end

			font = "#{Rails.root}/public/Arial.ttf"
			background =  background.combine_options do |i|
		        i.font font
		        i.gravity "West"
		        i.pointsize 50
		        i.draw "text 168, #{offset} '#{newcaption}'"
		        i.draw "text 1580, #{offset} '#{newcaption}'"
	      	end


			result = background.composite(img) do |c|
				 c.compose "Over"    # OverCompositeOp
				 if img[:width] == 1008
				 	c.geometry "+261+220" # copy second_image onto first_image from (20, 20)				 	
				 else
				 	c.geometry "+135+220" # copy second_image onto first_image from (20, 20)
				 end
			end
			
			result = result.composite(img) do |c|
				  c.compose "Over"    # OverCompositeOp
				  if img[:width] == 1008
					  c.geometry "+1682+220" # copy second_image onto first_image from (20, 20)
				  else
					  c.geometry "+1556+220" # copy second_image onto first_image from (20, 20)
				  end
			end

			#upload image to S3
			s3 = Aws::S3::Resource.new
			bucket = s3.bucket($ipbucket)
			obj = bucket.object(pid  + '_print.jpg')
			obj.put(body: result.to_blob)

		rescue Exception => e 
			Rails.logger.debug "**************** ERROR IN EDIT PIC ****************"
			Rails.logger.debug e.message  
		end
	end


	def print_pic_with_pid(pid=params[:pid])
		begin
			PhotoMailer.email_photo(pid).deliver
			head :ok
		rescue Exception => e 
			Rails.logger.debug "**************** ERROR IN PRINT PIC WITH PID****************"
			Rails.logger.debug e.message  
		end
	end
end


