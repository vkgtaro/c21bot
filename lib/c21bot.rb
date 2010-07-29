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
      attr_accessor :thanks_for_follow, :twitter_name

      def initialize(twitter_name, app_conf, user_conf)
        oauth = self.setup_oauth(app_conf, user_conf)

        self.twitter_name = twitter_name
        @twitter = ::Twitter::Base.new(oauth)
        @logger  = Logger.new(STDOUT)
      end

      def setup_oauth(app_conf, user_conf)
        oauth = ::Twitter::OAuth.new(app_conf[:consumer_key], app_conf[:consumer_secret])
        oauth.authorize_from_access(user_conf[:access_token], user_conf[:access_token_secret])

        oauth
      end

      def update(text, query={})
        status_id = ''

        # やりかたがおかしい
        text.gsub!(/.{110}/u) {|w|
          status_id = @twitter.update("#{w}", query)
          @logger.info "#{w}"
          ""
        }

        if text.size > 0
          status_id = @twitter.update("#{text}", query)
          @logger.info "#{text}"
        end

        return status_id
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

    def set_serif_for_refollow
      @thanks_for_follow = 'はい、フォローどうも'
    end

    def wait(time = 60)
        sleep( rand( time ) )
    end
  end

  class Man
    include C21::Twitter::Bot

    def set_serif_for_refollow
      @thanks_for_follow = 'ども、フォローありがとう'
    end
  end

  class Controller
    def initialize()
      self.setup_config()
      self.setup_man(@config.man['twitter_name'], @config.man['app_config'], @config.man['user_config'])
      self.setup_dog(@config.dog['twitter_name'], @config.dog['app_config'], @config.dog['user_config'])
      self.setup_serif(@config.app['serif_file'])

      @channel = @config.app['channel']
      @logger  = Logger.new(STDOUT)
    end

    def setup_config
      @config = C21::Twitter::Bot::Config.new()
    end

    def setup_man (twitter_name, app_conf, user_conf)
      @man = C21::Man.new(twitter_name, app_conf, user_conf)
      @man.set_serif_for_refollow
    end

    def setup_dog (twitter_name, app_conf, user_conf)
      @dog = C21::Dog.new(twitter_name, app_conf, user_conf)
      @dog.set_serif_for_refollow
    end

    def setup_serif (serif_file)
      @serif = C21::Twitter::Bot::Serif.new(serif_file)
    end

    def run()
      serif_line = @serif.select_line
      current_serif = @serif.parse_line(serif_line)

      tweet_by_man = @man.update("#{current_serif[0]} #{@channel}")
      unless tweet_by_man
        @logger.fatal("failed to update by man: #{$!}")
        abort "failed to update by man: #{$!}"
      end

      @dog.wait()
      @dog.update("@#{@man.twitter_name} #{current_serif[1]} #{@channel}", :in_reply_to_status_id => tweet_by_man.id)
    end

    def run_auto_refollow()
      @man.auto_refollow
      @dog.auto_refollow
    end
  end
end

