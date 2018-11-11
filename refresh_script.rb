#!/usr/bin/env ruby

while true
	begin		
		#production server 1
		#system('wget --quiet -O - http://production.4dyvwfpdk3.us-west-1.elasticbeanstalk.com/print_new_pics')

		#production server 2
		system('wget --quiet -O - http://production-2.us-west-1.elasticbeanstalk.com/print_new_pics')
								  
		#production server 3
		#system('wget --quiet -O - http://production-3.us-west-1.elasticbeanstalk.com/print_new_pics')

		#ip6 server 
		#system('wget --quiet -O - http://instaprinter6.us-west-1.elasticbeanstalk.com/print_new_pics')
		
		sleep 10
	rescue Exception => e 
		Rails.logger.debug "**************** ERROR IN refresh script ****************"
		Rails.logger.debug e.message  		
	end
end