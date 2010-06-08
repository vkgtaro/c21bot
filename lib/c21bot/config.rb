require 'yaml'
require 'singleton'

module C21Bot
  class Config
    include Singleton

    def read(dir='config')
      @config = {}
      @config[:aws] = YAML.load_file(dir + '/aws.yaml')
    end

    def database()
      @config[:database]
    end

    def aws()
      @config[:aws]
    end
  end
end

