class PhotoMailer < ApplicationMailer
	require 'open-uri'
	require 'aws-sdk'
	require 'tempfile'

	default from: ENV['username']

	def email_photo(pid)
		begin
			mg_client = Mailgun::Client.new ENV['api_key']
			mg_obj = Mailgun::MessageBuilder.new()

			# Define the from address
			mg_obj.set_from_address(ENV['username'], {"first"=>"Linus", "last" => "Liang"})

			# Define a to recipient

			#InstaPrinter4
			#mg_obj.add_recipient(:to, "instaprinter4@print.epsonconnect.com");  

			#InstaPrinter5
			#mg_obj.add_recipient(:to, "instaprinter5@print.epsonconnect.com");  

			#InstaPrinter6
			#mg_obj.add_recipient(:to, "instaprinter6@print.epsonconnect.com");  

			#InstaPrinter7
			mg_obj.add_recipient(:to, "instaprinter7@print.epsonconnect.com");  

			# Define the subject + body
			mg_obj.set_subject(pid)  
			mg_obj.set_text_body(pid)

			# read the image
			s3 = Aws::S3::Client.new
			resp = s3.get_object(bucket:'instaprinter7', key:pid + '_print.jpg')
		    tempfile = Tempfile.new(['hello', '.jpg'])
    		IO.copy_stream(resp.body, tempfile.path)
			mg_obj.add_attachment(tempfile.path, pid + "_print.jpg")

			# Finally, send your message using the client
			result = mg_client.send_message(ENV['domain'], mg_obj)

		rescue Exception => e  
			Rails.logger.debug "**************** ERROR IN email_photo() ****************"
			Rails.logger.debug e.message  
		end
	end
end
