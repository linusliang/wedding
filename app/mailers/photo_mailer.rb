class PhotoMailer < ApplicationMailer
	default from: ENV['username']

	def email_photo(pid)
		mg_client = Mailgun::Client.new ENV['api_key']
		mb_obj = Mailgun::MessageBuilder.new()

		# Define the from address
		mb_obj.set_from_address(ENV['username'], {"first"=>"Linus", "last" => "Liang"});  

		# Define a to recipient
		mb_obj.add_recipient(:to, "pve88645jh7ij8@print.epsonconnect.com");  

		# Define the subject + body
		mb_obj.set_subject("Instagram Picture");  
		mb_obj.set_text_body("body");

		# Attach a file and rename it
		mb_obj.add_attachment("#{Rails.root}/public/" + pid + '_print.jpg');

		# Finally, send your message using the client
		result = mg_client.send_message(ENV['domain'], mb_obj)
		puts result.body.to_s

	end
end
