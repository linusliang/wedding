class PhotoMailer < ApplicationMailer
	require 'open-uri'
	require 'aws-sdk'
	require 'tempfile'
	default from: ENV['username']

	def email_photo(pid)
		mg_client = Mailgun::Client.new ENV['api_key']
		mg_obj = Mailgun::MessageBuilder.new()

		# Define the from address
		mg_obj.set_from_address(ENV['username'], {"first"=>"Linus", "last" => "Liang"})

		# Define a to recipient
		#mb_obj.add_recipient(:to, "pve88645jh7ij8@print.epsonconnect.com");  
		mg_obj.add_recipient(:to, "linusliang@gmail.com")

		# Define the subject + body
		mg_obj.set_subject(pid)  
		mg_obj.set_text_body(pid)

		begin
			Rails.logger.debug "**************** sending file ****************"

			download = open("https://s3-us-west-1.amazonaws.com/tagprintshare/" + pid  + '_print.jpg')
		    tempfile = Tempfile.new(['hello', '.jpg'])
    		IO.copy_stream(download, tempfile.path)
			mg_obj.add_attachment(tempfile.path, pid + "_print.jpg")

		rescue Exception => e  
			Rails.logger.debug "**************** ERROR IN email_photo() ****************"
			Rails.logger.debug e.message  
		end

		# Finally, send your message using the client
		result = mg_client.send_message(ENV['domain'], mg_obj)

	end
end
