# frozen_string_literal: true
require 'thor'
require 'fileutils'
require 'flickraw'
require 'flickrage'

module Flickrage
  # CLI is here
  #
  class CLI < Thor # rubocop:disable ClassLength
    include Flickrage::Helpers::Log

    default_task :help

    map %w(c)  => :collage
    map %w(-V) => :version

    # Overriding Thor method for custom initialization
    #
    def initialize(*args)
      super

      setup_config
      set_logger
    end

    desc 'c / collage', 'Download & generate collage\'s'
    long_desc <<-LONGDESC
    `flickrage` is a tool which loves search on the Flickr & making collages from findings.

    You have to enter name of the output file and a max number of downloading files.

    Parameters helps you specify rectangle size for each image, collage name, it's location,
    ..., and well the grid base size.

    ### Examples

    Set keywords:

    $ flickrage -k some nice grapefruit

    Set Flickr API keys:

    $ flickrage --flickr-api-key SOMELONGKEY --flickr-shared-secret SOMELONGSECRET

    Select output folder:

    $ flickrage -k some nice grapefruit -o ./tmp

    Enter collage file_name:

    $ flickrage -k some nice grapefruit --file-name some.jpg

    Get collage of top 10 images:

    $ flickrage -k some nice grapefruit --max 10

    Get collage of top 20 images:

    $ flickrage -k some nice grapefruit --max 20

    Get collage of top 10 images custom width & height:

    $ flickrage -k some nice grapefruit --max 10 --width 160 --height 120

    VERSION: #{Flickrage::VERSION}
    LONGDESC
    method_option :keywords,
                  type: :array,
                  required: true,
                  aliases: %w(-k),
                  banner: 'some nice grapefruit'
    method_option :max,
                  type: :numeric,
                  enum: (1..20).to_a,
                  default: 10,
                  banner: '10',
                  desc: 'Select number of files.'
    method_option :grid,
                  type: :numeric,
                  banner: '2',
                  desc: 'Select grid base number.'
    method_option :width,
                  type: :numeric,
                  banner: '120',
                  desc: 'Set width for resize downloaded images.'
    method_option :height,
                  type: :numeric,
                  banner: '80',
                  desc: 'Set height for resize downloaded images.'
    method_option :log,
                  type: :string,
                  aliases: %w(-l),
                  banner: '/Users/someone/.flickrage/main.log',
                  desc: 'Log file path. By default logging is disabled.'
    method_option :output,
                  type: :string,
                  aliases: %w(-o),
                  banner: './tmp',
                  desc: 'Output directory, where all data will be stored.'
    method_option :file_name,
                  type: :string,
                  banner: './some.png',
                  desc: 'Name for file with collage.'
    method_option :dict_path,
                  type: :string,
                  banner: '/usr/share/dict/words',
                  desc: 'Path to file with multiline words (dictionary).'
    method_option :cleanup,
                  default: false,
                  type: :boolean,
                  aliases: %w(-c),
                  desc: 'Cleanup files before collage.'
    method_option :tagged_search,
                  default: false,
                  aliases: %w(-t),
                  type: :boolean,
                  desc: 'Search by tags.'
    method_option :verbose,
                  type: :boolean,
                  aliases: %w(-v),
                  desc: 'Verbose mode.'
    method_option :quiet,
                  type: :boolean,
                  aliases: %w(-q),
                  desc: 'Quiet mode. If don\'t need any messages and in console.'

    method_option :flickr_api_key,
                  type: :string,
                  banner: 'YOURLONGAPIKEY',
                  desc: 'FLICKR_API_KEY. if you can\'t use environment.'
    method_option :flickr_shared_secret,
                  type: :string,
                  banner: 'YOURLONGSHAREDSECRET',
                  desc: 'FLICKR_SHARED_SECRET. if you can\'t use environment.'

    def collage
      cleanup if options['cleanup']
      try_keys_first
      init_flickraw

      pipeline.run
    rescue Flickrage::NoKeysError, Flickrage::SearchError, Flickrage::DownloadError, Flickrage::CollageError,
           Flickrage::ResizeError, Flickrage::NumberError, Flickrage::PathError => e
      error_simple(e)
    rescue => e
      error_with_backtrace(e)
    end

    desc 'clean', 'Cleanup folder'
    method_option :output,
                  type: :string,
                  required: true,
                  aliases: %w(-o),
                  banner: './some'
    def clean
      cleanup
    end

    desc 'version, -V', 'Shows the version of the currently installed Flickrage gem'
    def version
      puts Flickrage::VERSION
    end

    no_commands do
      def error_simple(e)
        logger.error e.message
        raise e if Flickrage.config.verbose
      end

      def error_with_backtrace(e)
        logger.error e.message
        backtrace(e) if Flickrage.config.verbose
        raise e
      end

      def pipeline
        @pipeline ||= Pipeline.new(options)
      end

      def cleanup
        return logger.info('Output directory not exists, cleanup skipped') unless cleanup?
        FileUtils.rm_rf("#{options['output']}/.", secure: true)
      end

      def cleanup?
        options['output'] && Dir.exist?(options['output'])
      end

      def setup_config
        Flickrage.configure do |config|
          config.logger       = ::Logger.new(options['log']) if options['log']
          config.verbose      = options['verbose']
          config.quiet        = options['quiet']
          config.logger_level = Logger::DEBUG if config.verbose

          config.flickr_api_key       = options['flickr_api_key']       || ENV['FLICKR_API_KEY']
          config.flickr_shared_secret = options['flickr_shared_secret'] || ENV['FLICKR_SHARED_SECRET']

          config.dict_path = options['dict_path'] if options['dict_path']

          config.width  = options['width']  if options['width']
          config.height = options['height'] if options['height']

          config.max    = options['max']  if options['max']
          config.grid   = options['grid'] if options['grid']
          config.output = options['output']

          config.tagged_search = options['tagged_search']

          config.max = options['max'] if options['max']
          if config.max < 3
            STDERR.puts('Minimal value of max is: 3')
            config.max = 3
          end
        end
      end

      def set_logger
        Flickrage.logger = Log.new(shell: shell)
      end

      def backtrace(e)
        e.backtrace.each do |t|
          logger.error t
        end
      end

      def init_flickraw
        FlickRaw.api_key       = Flickrage.config.flickr_api_key
        FlickRaw.shared_secret = Flickrage.config.flickr_shared_secret
      end

      # Check for Flickr API keys
      def try_keys_first
        logger.debug 'Checking Flickr Key\'s.'

        return if Flickrage.api_keys?
        raise Flickrage::NoKeysError, 'You must provide Flickr API credentials via --flickr-api-key, --flickr-shared-secret via options. or have it in the environment'
      end
    end
  end
end
