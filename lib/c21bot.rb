# -*- coding: utf-8 -*-

$LOAD_PATH << "lib"

require 'rubygems'
require 'twitter'
require 'logger'
require 'oauth'
require 'yaml'
require 'singleton'
require 'c21bot/oauth-patch'

require 'pp'

if RUBY_VERSION >= '1.9.0'
  module Net   #:nodoc:
    module HTTPHeader
      def urlencode(str)
        str = str.to_s
        str.dup.force_encoding('ASCII-8BIT').gsub(/[^a-zA-Z0-9_\.\-]/){'%%%02x' % $&.ord}
      end
    end
  end
end

module C21
  module Twitter
    module Bot
      attr_accessor :thanks_for_follow

      def initialize(app_conf, user_conf, channel)
        oauth = self.setup_oauth(app_conf, user_conf)

        @channel = channel
        @twitter = Twitter::Base.new(oauth)
        @logger  = Logger.new(STDOUT)
      end

      def setup_oauth(app_conf, user_conf)
        oauth = Twitter::OAuth.new(app_conf[:consumer_key], app_conf[:consumer_secret])
        oauth.authorize_from_access(user_conf[:access_token], user_conf[:access_token_secret])
      end

      def update(text)
        @twitter.update("#{text} #{@channel}")
        @logger.info "#{text}"
      end

      def auto_refollow
        thanks_message = @thanks_for_follow ? @thanks_for_follow : "フォローありがとうございます！"
        friends = @twitter.friends
        @twitter.followers.each do |follower|
          if friends.include?(follower) == false
            begin
              @twitter.friendship_create(follower.id)
              update("@#{follower.screen_name} #{thanks_message}")
            rescue
              next
            end
          end
        end
      end

      class Serif
        def initialize(file)
          @file = setup_serif_file(file)
          @logger  = Logger.new(STDOUT)
        end

        def setup_serif_file(file)
          File.open(file).readlines
        rescue
          @logger.fatal("Can't read file: #{file}")
        end

        def select_line
          number = rand(@file.size)
          @file[number].chomp
        end

        def parse_line(line)
          result = []
          line.split("\t").each {|serif|
            matched = serif.match(/^.*『(.*)』/)
            result.push(matched[1])
          }

          result
        end
      end

      class Config
        def initialize(dir='config')
          @config = {}
          @config = YAML.load_file(dir + '/bot.yaml')
        end

        def dog
          @config['dog']
        end

        def man
          @config['man']
        end

        def app
          @config['app']
        end
      end

    end
  end

  class Dog
    include C21::Twitter::Bot
  end

  class Man
    include C21::Twitter::Bot
  end

  class Controller
    def initialize()
      self.setup_config()
      self.setup_man(@config.man['app_conf'], @config.man['user_conf'], @config.app['channel'])
      self.setup_dog(@config.dog['app_conf'], @config.dog['user_conf'], @config.app['channel'])
      self.setup_serif(@config.app['serif_file'])

      @logger  = Logger.new(STDOUT)
    end

    def setup_config
      @config = C21::Twitter::Bot::Config.new()
    end

    def setup_man (app_conf, user_conf, channel)
      @man = C21::Man.new(app_conf, user_conf, channel)
    end

    def setup_dog (app_conf, user_conf, channel)
      @dog = C21::Dog.new(app_conf, user_conf, channel)
    end

    def setup_serif (serif_file)
      @serif = C21::Twitter::Bot::Serif.new(serif_file)
    end

    def run()
      serif_line = @serif.select_line
      current_serif = @serif.parse_line(serif_line)

      begin
        @man.update(current_serif[0])
      rescue
        @logger.fatal('failed to update by man')
      end

      @dog.update(current_serif[1])

      @man.auto_follow
      @dog.auto_follow
    end
  end
end

