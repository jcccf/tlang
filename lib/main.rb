require 'twitter'
require 'json'
require 'pathname'
require 'optparse'
require_relative 'mtwitter'
require_relative 'mlang'

# Define some constants
DATA_DIRECTORY = "data"
DATA_DIR = Pathname.new(DATA_DIRECTORY)
USERS_DIR = DATA_DIR + "users"
USERS_SUSPENDED_DIR = DATA_DIR + "users_suspended"
USERS_SN_DIR = DATA_DIR + "users_by_screenname"
FOLLOWERS_DIR = DATA_DIR + "followers"
STATUSES_DIR = DATA_DIR + "statuses"
LANGUAGES_DIR = DATA_DIR + "languages"
LANGUAGES_LDIG_DIR = DATA_DIR + "languages_ldig"

# Make requisite directories if they don't already exist
def prepare_dirs
  require 'fileutils'
  [USERS_DIR, USERS_SUSPENDED_DIR, USERS_SN_DIR, FOLLOWERS_DIR, STATUSES_DIR, LANGUAGES_DIR, LANGUAGES_LDIG_DIR].each do |dir|
    FileUtils.mkdir_p dir unless File.exist? dir
  end
end

# Load from followers
def traverse_ff
  puts "Looking in followers directory to find people we haven't seen before"
  Dir.glob(FOLLOWERS_DIR + "*.txt").map{|f| [File.mtime(f), f]}.sort{|a,b| a[0] <=> b[0]}.map{|e| e[1]}.each do |filename|
    ff = json_from_file(filename)
    ff["friends"].each { |id| load_user_data(id) }
    ff["followers"].each { |id| load_user_data(id) }
  end
end

def traverse_languages # Uses detect language API
  puts "Looking in languages directory to load languages for people we haven't seen before"
  Dir.glob(USERS_DIR + "*.txt").map{|f| [File.mtime(f), f]}.sort{|a,b| a[0] <=> b[0]}.map{|e| e[1]}.each do |filename|
    uinfo = json_from_file(filename)
    load_languages(uinfo["id"])
  end
end

def traverse_languages_ldig # Uses LDig
  puts "Looking in languages directory to load languages for people we haven't seen before"
  Dir.glob(USERS_DIR + "*.txt").map{|f| [File.mtime(f), f]}.sort{|a,b| a[0] <=> b[0]}.map{|e| e[1]}.each do |filename|
    uinfo = json_from_file(filename)
    load_languages_ldig(uinfo["id"])
  end
end

# Load user info, statuses, friends/followers unless we already got them
def load_user_data(username_or_id)
  if (File.exist? USERS_DIR + "%s.txt" % username_or_id.to_s) or (File.exist? USERS_SUSPENDED_DIR + "%s.txt" % username_or_id.to_s) or (File.symlink? USERS_SN_DIR + "%s.txt" % username_or_id.to_s)
    puts "Skipping user %s..." % username_or_id.to_s
  else
    t = MTwitter.new
    uinfo = t.user(username_or_id)
    if uinfo.nil? # Invalid/suspended user, so add to suspended dir
      File.open(USERS_SUSPENDED_DIR + "%s.txt" % username_or_id.to_s, 'w') do |f|
        f.puts "1"
      end
    else
      # p uinfo
      fof = t.friends_and_followers(username_or_id)
      statuses = t.user_tweets(username_or_id, 100)
      json_to_file(uinfo, USERS_DIR + "%d.txt" % uinfo[:id])
      File.symlink(USERS_DIR + "%d.txt" % uinfo[:id], USERS_SN_DIR + "%s.txt" % uinfo[:screen_name]) # Create screen name symlink to userid file for easier lookup later
      json_to_file(fof, FOLLOWERS_DIR + "%d.txt" % uinfo[:id])
      json_to_file(statuses, STATUSES_DIR + "%d.txt" % uinfo[:id])
    end
  end
end

def load_languages(user_id)
  if File.exist? LANGUAGES_DIR + "%s.txt" % user_id.to_s
    puts "Skipping language test for %s..." % user_id.to_s
  else
    print "Loading languages for %s" % user_id.to_s
    STDOUT.flush
    languages = []
    statuses = json_from_file(STATUSES_DIR + "%s.txt" % user_id.to_s)
    statuses.each do |status|
      l = status["text"].language
      languages << { :language => l.best, :best_effort => l.best_effort, :raw => l.raw }
      print "."
      STDOUT.flush
    end
    json_to_file(languages, LANGUAGES_DIR + "%s.txt" % user_id.to_s)
    puts "wrote to file"
  end
end

def load_languages_ldig(user_id)
  if File.exist? LANGUAGES_LDIG_DIR + "%s.txt" % user_id.to_s
    puts "Skipping ldig language test for %s..." % user_id.to_s
  else
    print "Loading ldig languages for %s..." % user_id.to_s
    statuses = json_from_file(STATUSES_DIR + "%s.txt" % user_id.to_s)
    status_texts = statuses.map { |status| status["text"]}
    languages = MLdig.instance.languages(status_texts)
    json_to_file(languages, LANGUAGES_LDIG_DIR + "%s.txt" % user_id.to_s)
    puts "wrote to file"
  end
end

if __FILE__ == $0
  prepare_dirs

  OptionParser.new do |opts|
    opts.banner = "Usage: main.rb [options]"
    opts.on("-s", "--seed", "Seed") do |v|
      load_user_data("AndreasP")
    end
    opts.on("-f", "--friendsfollowers", "Load Data for Friends and Followers") do |v|
      traverse_ff
    end
    opts.on("-d", "--language", "Languages") do |v|
      traverse_languages_ldig
    end
    opts.on("-l", "--language", "Languages") do |v|
      traverse_languages
    end
  end.parse!
end