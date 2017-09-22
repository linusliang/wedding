require 'test_helper'

class PhotoMailerTest < ActionMailer::TestCase

  def photo_mail_preview
    PhotoMailer.photo_email()
  end

end
