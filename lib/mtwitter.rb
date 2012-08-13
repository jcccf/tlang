# encoding: utf-8
require 'twitter'
require 'json'
require 'singleton'
require 'zlib'
require_relative 'config'

# Structure
# MTwitter > initializes TwitterRL instance > calls Twitter class

class MTwitterRateLimitError < StandardError
end

# Wrapper around Twitter Class to handle Rate-Limiting
class TwitterRL
  include Singleton
  
  HIT_MIN = 50
  RECHECK_INTERVAL = 30
  
  def initialize(decorated = Twitter)
    update_rate_count
    @decorated = decorated
  end
  
  def update_rate_count
    @ratecount = Twitter.rate_limit_status.remaining_hits
    puts "Remaining Hits: %d" % @ratecount
    @recheck_in = TwitterRL::RECHECK_INTERVAL # Call remaining_hits again (which is expensive) after this number of decrements
  end
  
  def method_missing(method, *args)
    while @ratecount < TwitterRL::HIT_MIN # Keep sleeping if we're over our limit
      puts "Sleeping for 1 hour! (%d < %d hits remaining)" % [@ratecount, TwitterRL::HIT_MIN]
      sleep 3600
      update_rate_count
      # raise MTwitterRateLimitError
    end
    update_rate_count if @recheck_in == 0
    @ratecount -= 1
    @recheck_in -= 1
    
    done, result = false, nil
    while not done do
      begin
        result = args.empty? ? @decorated.send(method) : @decorated.send(method, *args) # This MUST BE THE LAST LINE
        done = true
      rescue Twitter::Error::ServiceUnavailable
        puts "Service Unavailable, sleeping for a while..."
        sleep 3600
      rescue Zlib::GzipFile::Error
        put "Gzip error, sleeping for a while..."
        sleep 60
      end
    end
    result
  end
end

# Convenience class to call usual Twitter methods
class MTwitter
  def initialize
    @MT = TwitterRL.instance
  end
  
  # Get information about a user
  def user(username_or_id)
    puts "Getting Info about User %s" % username_or_id.to_s
    begin
      u = @MT.user(username_or_id)
      string_data = {
        :name => u.name,
        :screen_name => u.screen_name,
        :location => u.location,
        :description => u.description,
        :url => u.url     
      }
      user_data = {
        :id => u.id,
        :followers_count => u.followers_count,
        :friends_count => u.friends_count,
        :protected => u.protected,
        :listed_count => u.listed_count,
        :created_at => u.created_at,
        :favourites_count => u.favourites_count,
        :utc_offset => u.utc_offset,
        :time_zone => u.time_zone,
        :geo_enabled => u.geo_enabled,
        :verified => u.verified,
        :statuses_count => u.statuses_count,
        :lang => u.lang,
        :is_translator => u.is_translator
      }
      string_data.each { |k,v| v.nil? ? (user_data[k] = nil) : (user_data[k] = v) }
      user_data
    rescue Twitter::Error::Unauthorized, Twitter::Error::Forbidden, Twitter::Error::NotFound
      puts "Suspended?"
      nil
    end
  end
  
  # Parse Place JSON
  def parse_place(place)
    if place.nil?
      nil
    else
      pl = {
        :id => place.id,
        :url => place.url,
        :place_type => place["place_type"],
        :name => place["name"],
        :full_name => place["full_name"],
        :country_code => place["country_code"],
        :country => place["country"]
        # "bounding_box"=>{"type"=>"Polygon", "coordinates"=>[[[9.633057, 55.953333], [10.092989, 55.953333], [10.092989, 56.216293], [9.633057, 56.216293]]]}, "attributes"=>{}
      }
      pl
    end
  end
  
  # Parse Entities JSON
  def parse_entities(entities)
    if entities.nil?
      nil
    else
      e = {
        :hashtags => entities["hashtags"].nil? ? nil : entities["hashtags"].map { |h| {:text => h["text"], :indices => h["indices"]} },
        :urls => entities["urls"].nil? ? nil : entities["urls"].map { |u| {:expanded_url => u["expanded_url"], :url => u["url"], :indices => u["indices"], :display_url => u["display_url"]} },
        :user_mentions => entities["user_mentions"].nil? ? nil : entities["user_mentions"].map { |u| {:screen_name => u["screen_name"], :name => u["name"], :id => u["id"], :indices => u["indices"]} }
      }
      e
    end
  end
  
  # Parse Retweeted Status JSON
  def parse_retweeted_status(rs)
    if rs.nil?
      nil
    else
      rs = { 
        :created_at => rs.created_at,
        :id => rs.id,
        :text => rs.text,
        :source => rs.source, 
        :truncated => rs["truncated"],
        :in_reply_to_status_id => rs["in_reply_to_status_id"],
        :in_reply_to_user_id => rs["in_reply_to_user_id"],
        :in_reply_to_screen_name => rs["in_reply_to_screen_name"],
        :user_id => rs["user"]["id"]        
      }
      rs
    end
  end
  
  # Get information about a user's tweets
  def user_tweets(user, count=10, since_id=nil, max_id=nil)
    print "Getting Last %d Statuses for User %s" % [count, user.to_s]
    print " since %s" % since_id if since_id
    print " until %s" % max_id if max_id
    print "\n"
    options = {:count => count, :trim_user => true, :include_rts => true, :include_entities => true}
    options[:since_id] = since_id if since_id
    options[:max_id] = max_id if max_id
    begin
      statuses = @MT.user_timeline(user, options)
      if statuses.size > 0
        status_data = statuses.map do |s|
          {
            :user_id => s.user.id,
            :created_at => s.created_at,
            :id => s.id,
            :text => s.text,
            :source => s.source,
            :truncated => s["truncated"],
            :in_reply_to_user_id => s["in_reply_to_user_id"],
            :in_reply_to_screen_name => s["in_reply_to_screen_name"],
            :geo => s["geo"],
            :coordinates => s["coordinates"],
            :place => parse_place(s["place"]),
            :contributors => s["contributors"],
            :retweet_count => s["retweet_count"],
            :entities => parse_entities(s.attrs["entities"]),
            :retweeted_status => parse_retweeted_status(s["retweeted_status"])
          }
        end
        status_data
      else
        []
      end
    rescue Twitter::Error::Unauthorized, Twitter::Error::Forbidden
      puts "Failed for %s (Protected)" % user.to_s
      []
    end
  end
  
  # Get list of friend (people you follow) and follower IDs
  def friends_and_followers(username_or_id)
    puts "Getting Friends and Followers for %s..." % username_or_id.to_s
    begin
      friend_ids = @MT.friend_ids(username_or_id).ids
      follower_ids = @MT.follower_ids(username_or_id).ids
      { :friends => friend_ids, :followers => follower_ids }
    rescue Twitter::Error::Unauthorized, Twitter::Error::Forbidden
      puts "Failed for %s (Protected)" % username_or_id.to_s
      { :friends => [], :followers => [] }
    end
  end
  
end

# JSON Convenience Methods
def json_to_file(object, filename)
  File.open(filename, 'w') do |f|
    f.write(JSON.generate(object))
  end
end
def json_from_file(filename)
  d = nil
  File.open(filename, 'r') do |f|
    d = f.read
  end
  JSON.parse(d)
end

if __FILE__ == $0
  t = MTwitter.new
  uinfo = t.user("AndreasP")
  p uinfo
  fof = t.friends_and_followers("AndreasP")
  statuses = t.user_tweets("AndreasP", 100)
  json_to_file(uinfo, "data/users/%d.txt" % uinfo[:id])
  json_to_file(fof, "data/followers/%d.txt" % uinfo[:id])
  json_to_file(statuses, "data/statuses/%d.txt" % uinfo[:id])
end