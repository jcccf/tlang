# encoding: utf-8
require 'net/http'
require 'uri'
require 'json'
require 'singleton'
require 'open3'
require_relative 'config'
require_relative 'mfile'

# Class to store language information
class MLanguages
  attr_reader :raw
  
  def initialize(json)
    @raw = json['data']['detections']
  end
  
  # Return all possible languages
  def all
    @raw.map { |l| l['language'] }
  end
  
  # Return most confident language
  def best
    (@raw.size > 0) ? @raw.sort { |a, b| a['confidence'] <=> b['confidence'] }[0]['language'] : nil
  end
  
  # Make a best effort attempt to return all "reasonable" languages
  def best_effort
    @raw.find_all { |l| l['confidence'] > 0.1 && l['language'] != "xxx" }.sort { |a, b| b['confidence'] <=> a['confidence'] }.map { |l| l['language'] }
  end
end

class MDetectLanguage
  def language(string)
    uri = URI.parse(URI.escape("http://ws.detectlanguage.com/0.2/detect?q=%s&key=%s" % [string, DETECT_LANGUAGE_API_KEY]))
    result = nil
    while result.nil?
      response = Net::HTTP.get_response(uri)
      result = case response
      when Net::HTTPSuccess
        response.body
      else
        puts "Sleeping for half an hour"
        sleep(1800)
        nil
      end
    end
    sleep 1
    MLanguages.new(JSON.parse(result))
  end
end

class MDetectLanguageRateLimiter
  include Singleton
  
  def initialize
    @decorated = MDetectLanguage.new
    @rate = 1000
    @sleep_seconds = 2600
    @current_count = @rate
  end
  
  def method_missing(method, *args)
    if @current_count == 0
      puts "Sleeping for %d seconds..." % @sleep_seconds
      sleep @sleep_seconds
      @current_count = @rate
    end
    @current_count -= 1
    args.empty? ? @decorated.send(method) : @decorated.send(method, *args) # This MUST BE THE LAST LINE
  end
end

class MLdig
  include Singleton
  
  def language(string)
    languages([string])[0]
  end
  
  def languages(stringlist)
    langs = []
    # Temporarily write to file
    chdir_return('../ldig') do
      File.open('test.txt', 'w') do |f|
        stringlist.each do |stringy|
          f.puts "en\t%s" % stringy.gsub(/\t/, '')
        end
      end
      stdin, stdout, stderr = Open3.popen3("python ldig.py -m models/model.latin test.txt")
      while l = stdout.gets
        if /[a-zA-Z]{2}\t(?<lang>[a-zA-Z]{2})\t[.]*/ =~ l
          langs << lang
        end
      end
    end
    langs
  end
end

class String
  # Use Detect Language to get language, and then return an MLanguages object
  def language
    MDetectLanguageRateLimiter.instance.language(self)
    # MLdig.instance.language(self)
  end
end

if __FILE__ == $0
  # l = "昨晩のanother打ち上げに続き、今晩はアニメシャナ打ち上げなう".language # Should be ja and en
  # l = "恒例のアレ http://pic.twitter.com/efZO7U4t".language # Should be ja only
  # l = "お、つり球OPだ( ´ ▽ ` )EDもだけど、曲がまたずるいよなあ(*'-'*)".language # Should be JA only
  # l = "ヽ(；▽；)ノ RT @HISASHI_: ＿|￣|○ RT @itoww: ！！や、やばい、忘れてきましたわ…！ RT @lizardtyan: @itoww HISASHIさんが「ジョイスティックをもってこい」と呟かれて…".language # Should be JA only
  # puts l.best_effort
  # puts l.raw
  puts MLdig.instance.languages(["kitty meow", "wagga coo", "bonjour monsieur"])
end