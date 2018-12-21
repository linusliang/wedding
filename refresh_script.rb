#!/usr/bin/env ruby

while true
	begin		
		# servers
		#system('wget --quiet -O - http://production.4dyvwfpdk3.us-west-1.elasticbeanstalk.com/print_new_pics')
		#system('wget --quiet -O - http://production-2.us-west-1.elasticbeanstalk.com/print_new_pics')
		#system('wget --quiet -O - http://production-3.us-west-1.elasticbeanstalk.com/print_new_pics')
		#system('wget --quiet -O - http://instaprinter5.us-west-1.elasticbeanstalk.com/print_new_pics')
		#system('wget --quiet -O - http://instaprinter6.us-west-1.elasticbeanstalk.com/print_new_pics')
		#system('wget --quiet -O - http://instaprinter7.us-west-1.elasticbeanstalk.com/print_new_pics')
		#system('wget --quiet -O - http://instaprinter8.us-west-1.elasticbeanstalk.com/print_new_pics')
		#system('wget --quiet -O - http://instaprinter9.us-west-1.elasticbeanstalk.com/print_new_pics')
		#system('wget --quiet -O - http://instaprinter10.us-west-1.elasticbeanstalk.com/print_new_pics')
		
		sleep 10
	rescue Exception => e 
		Rails.logger.debug "**************** ERROR IN refresh script ****************"
		Rails.logger.debug e.message  		
	end
end