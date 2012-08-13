# encoding: utf-8
require 'twitter'
require 'json'
require 'mysql'
require 'time'
require 'yaml'
require_relative 'mtwitter'
require_relative 'mlang'

def mysql_connect
  dbconf = YAML::load(File.open('database.yml'))['mysql']
  my = Mysql::new(dbconf["host"], dbconf["username"], dbconf["password"], dbconf["database"])
  my.options(Mysql::SET_CHARSET_NAME, 'utf8')
  my
end

user_id = 15286172

def run_users_queue
  my = mysql_connect
  # Get a user from the queue
  while true do
    # Get an id from the queue atomically
    my.query("START TRANSACTION;")
    res = my.query("SELECT * FROM users_queue WHERE processing = 0 ORDER BY id ASC LIMIT 1")
    break if res.num_rows == 0
    user_id = res.fetch_hash['user_id']
    my.query("UPDATE users_queue SET processing = 1 WHERE user_id = %s" % user_id)
    my.query("COMMIT")

    # Load users and insert friends
    friend_ids = load_user(my, user_id.to_i)
    friend_ids.each do |fid|
      my.query("INSERT INTO users_queue SET user_id = %s" % fid)
    end
    puts "Queued %s friends" % friend_ids.size

    # If all successful, remove from queue
    my.query("DELETE FROM users_queue WHERE user_id = %s" % user_id)
  end
  puts "Ended; Nothing in the queue"
end

def load_user(my, user_id)
  fids = []
  st = my.prepare "SELECT * FROM users WHERE user_id = ?"
  res = st.execute user_id
  user = (res.num_rows == 0) ? nil : res.fetch_hash
  if user && (user['invalid'] == 1 || user['completed'] == 1)
    puts "Skipping %s" % user_id
  else
    puts "Loading %s" % user_id
    t = MTwitter.new
    uinfo = t.user(user_id)
    if uinfo.nil?
      st = my.prepare "INSERT INTO users (user_id, invalid) VALUES (?, ?)"
      st.execute user_id, 1
      puts "Invalid user_id %s" % user_id
    else
      uid = uinfo[:id]
      puts uinfo[:screen_name]
      # Add user
      if user
        st = my.prepare "UPDATE users SET screen_name = ?, json = ? WHERE user_id = ?"
        st.execute uinfo[:screen_name], JSON.generate(uinfo), uid
      else
        st = my.prepare "INSERT INTO users (user_id, screen_name, json) VALUES (?, ?, ?)"
        st.execute uid, uinfo[:screen_name], JSON.generate(uinfo)
      end

      # Add edges
      fof = t.friends_and_followers(uid)
      fof[:friends].each do |fid|
        st = my.prepare "INSERT IGNORE INTO edges (source_id, target_id, by_id) VALUES(?, ?, ?)"
        st.execute uid, fid, uid
      end
      fids = fof[:friends]
      fof[:followers].each do |fid|
        st = my.prepare "INSERT IGNORE INTO edges (source_id, target_id, by_id) VALUES(?, ?, ?)"
        st.execute fid, uid, uid
      end

      # Add statuses
      # If we've added this user before, get most recent saved status and get everything since then
      # If not, simply get the last 200 tweets
      st = my.prepare "SELECT id FROM statuses WHERE user_id = ? ORDER BY created_at DESC LIMIT 1"
      res = st.execute uid
      if res.num_rows > 0
        since_id = res.fetch_hash['id']
        statuses = t.user_tweets(uid, 200, since_id)
        while statuses.size > 0
          puts "\tAdding..."
          statuses.each do |status|
            st = my.prepare "INSERT INTO statuses (id, user_id, json, created_at) VALUES (?, ?, ?, ?)"
            st.execute status[:id], uid, JSON.generate(status), status[:created_at].getutc
          end
          statuses = t.user_tweets(uid, 200, since_id, statuses[-1][:id]-1)
        end
      else
        statuses = t.user_tweets(uid, 200)
        statuses.each do |status|
          st = my.prepare "INSERT INTO statuses (id, user_id, json, created_at) VALUES (?, ?, ?, ?)"
          st.execute status[:id], uid, JSON.generate(status), status[:created_at].getutc
        end
      end

      # Mark as completed
      st = my.prepare "UPDATE users SET completed = 1 WHERE user_id = ?"
      st.execute uid
    end
  end
  fids
end

run_users_queue

