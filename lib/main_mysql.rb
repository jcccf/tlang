require 'twitter'
require 'json'
require 'mysql'
require_relative 'mtwitter'
require_relative 'mlang'

user_id = 17466073
my = Mysql::new("localhost", "root", "", "twitter")
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
    statuses = t.user_tweets(username_or_id, 100)
    #TODO

    # Mark as completed
    st = my.prepare "UPDATE users SET completed = 1 WHERE user_id = ?"
    st.execute uid
  end
end