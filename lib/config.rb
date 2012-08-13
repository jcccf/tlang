require 'twitter'
require 'yaml'

yamlconf = YAML::load(File.open('database.yml'))

Twitter.configure do |config|
  conf = yamlconf['twitter']
  config.consumer_key = conf['consumer_key']
  config.consumer_secret = conf['consumer_secret']
  config.oauth_token = conf['oauth_token']
  config.oauth_token_secret = conf['oauth_token_secret']
end

DETECT_LANGUAGE_API_KEY = yamlconf['detect_language']['api_key']