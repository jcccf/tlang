require 'twitter'
require 'json'
require 'pathname'
require_relative 'mtwitter'

# Define some constants
DATA_DIRECTORY = "data"
DATA_DIR = Pathname.new(DATA_DIRECTORY)
USERS_DIR = DATA_DIR + "users"
USERS_SN_DIR = DATA_DIR + "users_by_screenname"
FOLLOWERS_DIR = DATA_DIR + "followers"
STATUSES_DIR = DATA_DIR + "statuses"

# Make requisite directories if they don't already exist
def prepare_dirs
  require 'fileutils'
  [USERS_DIR, USERS_SN_DIR, FOLLOWERS_DIR, STATUSES_DIR].each do |dir|
    FileUtils.mkdir_p dir unless File.exist? dir
  end
end

# Load from followers
def traverse_ff
  puts "Looking in followers directory to find people we haven't seen before"
  Dir.glob(FOLLOWERS_DIR + "*.txt").each do |filename|
    ff = json_from_file(filename)
    ff["friends"].each { |id| load_user_data(id) }
    ff["followers"].each { |id| load_user_data(id) }
  end
end

# Load user info, statuses, friends/followers unless we already got them
def load_user_data(username_or_id)
  if (File.exist? USERS_DIR + "%s.txt" % username_or_id.to_s) or (File.symlink? USERS_SN_DIR + "%s.txt" % username_or_id.to_s)
    puts "Skipping user %s..." % username_or_id.to_s
  else
    t = MTwitter.new
    uinfo = t.user(username_or_id)
    # p uinfo
    fof = t.friends_and_followers(username_or_id)
    statuses = t.user_tweets(username_or_id, 100)
    json_to_file(uinfo, USERS_DIR + "%d.txt" % uinfo[:id])
    File.symlink(USERS_DIR + "%d.txt" % uinfo[:id], USERS_SN_DIR + "%s.txt" % uinfo[:screen_name]) # Create screen name symlink to userid file for easier lookup later
    json_to_file(fof, FOLLOWERS_DIR + "%d.txt" % uinfo[:id])
    json_to_file(statuses, STATUSES_DIR + "%d.txt" % uinfo[:id])
  end
end

if __FILE__ == $0
  prepare_dirs
  load_user_data("AndreasP")
  traverse_ff
end