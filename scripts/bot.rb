#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

$LOAD_PATH << "lib"

require 'c21bot'

c21bot = C21::Controller.new
c21bot.run

# require 'twitter'
# 
# class TwitterBot
#   attr_accessor :thanks_for_follow
# 
#   def initialize(app_conf, user_conf, channel)
#     oauth = self.setup_oauth(app_conf, user_conf)
# 
#     @channel = channel
#     @twitter = ::Twitter::Base.new(oauth)
#     @logger  = Logger.new(STDOUT)
#   end
# 
#   def setup_oauth(app_conf, user_conf)
#     oauth = ::Twitter::OAuth.new(app_conf[:consumer_key], app_conf[:consumer_secret])
#     oauth.authorize_from_access(user_conf[:access_token], user_conf[:access_token_secret])
# 
#     oauth
#   end
# 
#   def update(text, query={})
#     status_id = @twitter.update("#{text} #{@channel}", query)
#     @logger.info "#{text}"
# 
#     status_id
#   end
# 
#   def auto_refollow
#     thanks_message = @thanks_for_follow ? @thanks_for_follow : "フォローありがとうございます！"
#     friends = @twitter.friends
#     @twitter.followers.each do |follower|
#       if friends.include?(follower) == false
#         begin
#           @twitter.friendship_create(follower.id)
#           update("@#{follower.screen_name} #{thanks_message}")
#         rescue
#           next
#         end
#       end
#     end
#   end
# 
# end
# 
# 
# config = C21::Twitter::Bot::Config.new()
# man = TwitterBot.new(config.dog['app_config'], config.dog['user_config'], '#iq_test_hoge')
# man.update("Hey! #iqtest21")


