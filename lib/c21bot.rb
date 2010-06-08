# -*- coding: utf-8 -*-

$LOAD_PATH << "lib"

require 'rubygems'
require 'twitter'
require 'logger'
require 'oauth'
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
        thanks_message = @thanks_for_follow ? @thanks_for_follow
                                            : "フォローありがとうございます！"
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
          line.split("\t").each {|serif|
            # Regex で対応できるはず
            serif.gsub!(/.*「/, '').gsub!(/」/, '')
          }
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
end

# dog = C21::Dog.new('aaa')
# man = C21::Man.new('bbb')

serif = C21::Twitter::Bot::Serif.new('hoge')
line = serif.select_line
p serif.parse_line(line)
