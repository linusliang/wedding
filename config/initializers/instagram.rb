require "instagram"

Instagram.configure do |config|
  config.client_id = "c30b8ff203f64abba9cbc11d353eee9f"
  config.client_secret = "87da4a0ac8f04cbf8158a23579ffd06d"
  # For secured endpoints only
  #config.client_ips = '<Comma separated list of IPs>'
end