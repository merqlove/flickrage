require 'flickrage/version'
require 'dry-configurable'
require 'dry-types'

module Flickrage
  autoload :Log,      'flickrage/log'
  autoload :Helpers,  'flickrage/helpers'
  autoload :Types,    'flickrage/types'
  autoload :Entity,   'flickrage/entity'
  autoload :Service,  'flickrage/service'
  autoload :Pipeline, 'flickrage/pipeline'

  extend Dry::Configurable

  setting :logger
  setting :logger_level, Logger::INFO

  setting :verbose, false
  setting :quiet,   false
  setting :cleanup, false

  setting :resize_file_prefix, 'resized.'

  setting :pool_size, 5
  setting :pool

  setting :max, 10
  setting :output

  setting :dict_path, '/usr/share/dict/words'
  setting :dict

  setting :flickr_api_key
  setting :flickr_shared_secret

  class << self
    def cleanup
      config.logger.close if config.logger
    end

    def logger
      config.logger
    end

    def has_api_keys?
      config.flickr_api_key && config.flickr_shared_secret
    end

    def pool
      config.pool
    end

    def pool=(value)
      config.pool = value
    end

    def dict
      return config.dict if config.dict
      configure do |c|
        fail DictError, "Not found #{config.dict_path}" unless File.exist?(config.dict_path)
        c.dict = File.readlines(config.dict_path)
      end
      config.dict
    end
  end

  # Standard Request Exception. When we don't need droplet instance id.
  #
  class BaseError < StandardError; end

  # User did few mistakes with output path...
  #
  class PathError < BaseError
    def initialize(*args)
      Flickrage.logger.error 'Please provide right output path...'
      super
    end
  end

  # User system has no/wrong default words dict...
  #
  class DictError < BaseError
    def initialize(*args)
      Flickrage.logger.error 'Please provide right path to the dict...'
      super
    end
  end

  # User did few mistakes with size input...
  #
  class NumberError < BaseError
    def initialize(*args)
      Flickrage.logger.error "Flickrage support for dimensions only numbers in range: #{args[0]}..."
      super
    end
  end

  # Download error rises when Flickr down...
  #
  class SearchError < BaseError
    def initialize(*args)
      Flickrage.logger.error "Droplet id: #{args[0]} Not Found"
      super
    end
  end

  # Download error rises when Flickr down...
  #
  class DownloadError < BaseError
    def initialize(*args)
      Flickrage.logger.error "Connection is down or something goes wrong...: #{args[0]}"
      super
    end
  end

  # Every call must have token in environment or via params.
  #
  class NoKeysError < BaseError
    def initialize(*_args)
      Flickrage.logger.error 'Please enter Flickr keys'
      super
    end
  end

  # Can't find output path?
  #
  class SaveError < BaseError
    def initialize(*args)
      Flickrage.logger.error "Something wrong with output path: #{args[0]}"
      super
    end
  end

  # Here is something with imagemagick?
  #
  class ResizeError < BaseError
    def initialize(*args)
      Flickrage.logger.error "Something wrong with resize tools: #{args[0]}"
      super
    end
  end

  # Here is something with imagemagick?
  #
  class CollageError < BaseError
    def initialize(*args)
      Flickrage.logger.error "Something wrong with collage tools: #{args[0]}"
      super
    end
  end
end
