# frozen_string_literal: true
require 'flickrage/version'
require 'dry-configurable'
require 'dry-types'

module Flickrage
  autoload :Log,      'flickrage/log'
  autoload :Helpers,  'flickrage/helpers'
  autoload :Types,    'flickrage/types'
  autoload :Entity,   'flickrage/entity'
  autoload :Service,  'flickrage/service'
  autoload :Worker,   'flickrage/worker'
  autoload :Pipeline, 'flickrage/pipeline'

  extend Dry::Configurable

  MAX_DICT_LINES = 1_000_000

  setting :logger
  setting :logger_level, Logger::INFO

  setting :verbose, false
  setting :quiet,   false
  setting :cleanup, false

  setting :resize_file_prefix, 'resized.'

  setting :width
  setting :height

  setting :pool_size, 5
  setting :pool

  setting :tagged_search, false

  setting :search_timeout, 30
  setting :download_timeout, 10

  setting :grid, 2
  setting :max, 10
  setting :output

  setting :dict_path, '/usr/share/dict/words'
  setting :dict

  setting :flickr_api_key
  setting :flickr_shared_secret

  class << self
    attr_accessor :logger

    def cleanup
      logger.close if logger
    end

    def api_keys?
      config.flickr_api_key && config.flickr_shared_secret
    end

    def pool=(value)
      config.pool = value
    end

    def dict
      return config.dict if config.dict
      _read_dict
    end

    def _read_dict
      logger.debug('Caching lines from the Dict')

      raise DictError, "Not found #{config.dict_path}" unless File.exist?(config.dict_path)
      @dict_file = File.open(config.dict_path, 'r')

      configure do |c|
        c.dict = @dict_file.each_line.first(MAX_DICT_LINES)
      end
      config.dict
    rescue => e
      raise DictError, e.message
    ensure
      @dict_file.close if @dict_file.respond_to?(:close)
    end
  end

  # Standard Request Exception. When we don't need droplet instance id.
  #
  class BaseError < StandardError; end

  # Time is going over...
  #
  class SystemTimeout < BaseError
    def initialize(*args)
      Flickrage.logger.error 'Timeout, something going wrong...'
      super
    end
  end

  # User did few mistakes with output path...
  #
  class PathError < BaseError
    def initialize(*args)
      Flickrage.logger.error 'Please provide existing output path...'
      super
    end
  end

  # User did few mistakes with file_name...
  #
  class FileNameError < BaseError
    def initialize(*args)
      Flickrage.logger.error 'Please provide right file_name...'
      super
    end
  end

  # User system has no/wrong default words dict...
  #
  class DictError < BaseError
    def initialize(*args)
      Flickrage.logger.error 'Please provide existing path to the dict...'
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
      Flickrage.logger.error "Cannot find something...: #{args[0]}"
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

  # Something wrong with the process?
  #
  class CollageError < BaseError
    def initialize(*args)
      Flickrage.logger.error "Something wrong with collage tools: #{args[0]}"
      super
    end
  end
end
