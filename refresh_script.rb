#!/usr/bin/env ruby

while true
	begin		
		system('wget --quiet -O - http://production.4dyvwfpdk3.us-west-1.elasticbeanstalk.com/print_new_pics')
		sleep 15
	rescue Exception => e 
		Rails.logger.debug "**************** ERROR IN refresh script ****************"
		Rails.logger.debug e.message  		
	end
end