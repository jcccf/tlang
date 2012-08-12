require 'twitter'
require 'json'
require 'mysql'
require 'time'
require 'yaml'
require_relative 'mtwitter'
require_relative 'mlang'

def mysql_connect
  dbconf = dbconf = YAML::load(File.open('database.yml'))
  Mysql::new(dbconf["host"], dbconf["username"], dbconf["password"], dbconf["database"])
end

user_id = 15286172

def load_user(user_id)
  my = mysql_connect
  st = my.prepare "SELECT * FROM users WHERE user_id = ?"
  res = st.execute user_id
  user = (res.num_rows == 0) ? nil : res.fetch_hash
  if user && (user['invalid'] == 1 || user['completed'] == 1)
    puts "Skipping %s" % user_id
  else
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
end

