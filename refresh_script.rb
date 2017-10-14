#!/usr/bin/env ruby

while true
	begin		
		system('wget --quiet -O - http://localhost:3000/print_new_pics')
		sleep 30
	rescue Exception => e 
		Rails.logger.debug "**************** ERROR IN refresh script ****************"
		Rails.logger.debug e.message  		
	end
end