#!/usr/bin/env ruby
# coding: utf-8

require 'rubygems'
require 'oauth'
# require 'oauth-patch'

if RUBY_VERSION >= '1.9.0'
  # エンコーディングの違いのせいで、
  # 日本語の文字列をpostパラメータに含めようとするとエラーが出ます。
  # 無理矢理エンコーディングをUTF-8に変えて再試行することで回避。
  module OAuth
    module Helper
      def escape(value)
        begin
          URI::escape(value.to_s, OAuth::RESERVED_CHARACTERS)
        rescue ArgumentError
          URI::escape(
            value.to_s.force_encoding(Encoding::UTF_8),
            OAuth::RESERVED_CHARACTERS
          )
        end
      end
    end
  end

  # 1.9から文字列がEnumerableでなくなりましたので、
  # その対応をしています。
  module HMAC
    class Base
      def set_key(key)
        key = @algorithm.digest(key) if key.size > @block_size
        key_xor_ipad = Array.new(@block_size, 0x36)
        key_xor_opad = Array.new(@block_size, 0x5c)
        key.bytes.each_with_index do |value, index|
          key_xor_ipad[index] ^= value
          key_xor_opad[index] ^= value
        end
        @key_xor_ipad = key_xor_ipad.pack('c*')
        @key_xor_opad = key_xor_opad.pack('c*')
        @md = @algorithm.new
        @initialized = true
      end
    end
  end
end

CONSUMER_KEY = 'D4DM23mX1UAinZlQBv1ptg' # ←ここを書き換える
CONSUMER_SECRET = 'CBqCIDsKPUTBIKOyhHynPrbfgqYjYxlkKDJw3dzgWk' # ←ここを書き換える

consumer = OAuth::Consumer.new(
  CONSUMER_KEY,
  CONSUMER_SECRET,
  :site => 'http://twitter.com'
)

request_token = consumer.get_request_token

puts "Access this URL and approve => #{request_token.authorize_url}"

print "Input OAuth Verifier: "
oauth_verifier = gets.chomp.strip

access_token = request_token.get_access_token(
  :oauth_verifier => oauth_verifier
)

puts "Access token: #{access_token.token}"
puts "Access token secret: #{access_token.secret}"
