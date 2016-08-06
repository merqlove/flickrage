require 'concurrent-edge'
require 'mini_magick'

module Flickrage
  class Pipeline
    include Flickrage::Helpers::Log
    include Flickrage::Helpers::Tty
    include Flickrage::Helpers::Dict

    MAX_ASK_ERRORS = 3
    MIN_IMAGE_SIZE = 100
    MAX_IMAGE_SIZE = 500

    PRINT_IMAGE_HEADERS_LITE = %w(keyword id)
    PRINT_IMAGE_HEADERS      = PRINT_IMAGE_HEADERS_LITE + %w(url title width height)


    attr_accessor :opts

    def default_opts
      {
        resizer:    Service::Resizer,
        composer:   Service::Composer,
        downloader: Service::Downloader,
        search:     Service::Search
      }
    end

    def initialize(opts = {})
      @opts = default_opts.merge(opts)
      @opts[:ask_error_counter] = 0
    end

    #
    # Main pipeline
    #
    def run
      Concurrent
        .future { search(opts['keywords']) }
        .then { |links| download(links) }
        .then { |files| resize(files) }
        .then { |files| compose(files) }
        .then { |n| logger.info("#{n || 0} files composed") }
        .rescue { |e| logger.error(e) }
        .wait
    end

    private

    #
    # Steps
    #

    def search(keywords)
      searcher = opts[:search].new

      keywords += sample_words(Flickrage.config.max - keywords.size) if keywords.size < Flickrage.config.max
      keys = keywords.join(', ')

      logger.debug("Received keywords: [#{keys}]")
      logger.debug('Searching is starting')

      spinner(message: "Searching by keywords: [#{keys}]") do |spin|
        # files = keywords.each_with_index.map do |k, i|
        #   Concurrent
        #   .future(thread_pool) do
        #     sleep(i)
        #     searcher.run(k)
        #   end
        #   .then do |r|
        #     spin.update(title: "(found image ID##{r.id})") if r
        #     r
        #   end
        #   .rescue { |e|
        #     spin.error( "is failed: #{e.message}" )
        #   }
        # end
        #
        # result = Concurrent.zip(*files).value.compact.flatten
        #
        # fail Flickrage::SearchError if spin.error?
        #
        # spin.success
        #
        # success_keywords = result.map(&:keyword)
        # fault_words = keywords - success_keywords

        image_list = finder(keywords, searcher, spin)

        # logger.info("Found #{result.size} images:")
        # speaker.print_table([PRINT_IMAGE_HEADERS] + result.map{ |i|
        #   [i.keyword, i.id, i.url, i.title, i.width, i.height]
        # })
        #
        # logger.info('Not found keywords:')
        # speaker.print_table(fault_words.map{ |word|
        #   [word]
        # })

        clean_thread_pool

        fail Flickrage::SearchError if spin.error?

        spin.success

        logger.info("Found #{image_list.total} images:")
        speaker.print_table([PRINT_IMAGE_HEADERS] + image_list.images.map{ |i|
          [i.keyword, i.id, i.url, i.title, i.width, i.height]
        })

        logger.info('Not found keywords:')
        speaker.print_table(image_list.not_founds.map{ |word|
          [word]
        })

        image_list

        # Flickrage::Entity::ImageList.new(images: result, total: result.size, not_founds: fault_words)
      end
    end

    def finder(keywords, searcher, spin, images = nil)
      files = keywords.map do |k|
        Concurrent
        .future(thread_pool) do
          # sleep(1)
          searcher.run(k)
        end
        .then do |r|
          spin.update(title: "(found image ID##{r.id})") if r
          r
        end
        .rescue { |e| spin.error( "is failed: #{e.message}" ) }
      end

      result = Concurrent.zip(*files).value.compact.flatten

      if images
        images.combine(result)
        images.clean
      else
        images = Flickrage::Entity::ImageList.new(images: result,
                                                  total:  result.size)
      end

      if images.valid?
        images
      else
        success_keywords = result.map(&:keyword)
        not_founds = keywords - success_keywords
        images.not_founds += not_founds

        keywords = sample_words(not_founds.size) if not_founds&.size > 0

        finder(keywords, searcher, spin, images)
      end
    end

    def download(image_list)
      logger.debug('Downloading is starting')

      init_output

      downloader = opts[:downloader].new

      spinner(message: "Downloading #{image_list.size} images") do |spin|
        files = image_list.images.each_with_index.map do |image, i|
          Concurrent
            .future(thread_pool) do
              # sleep(i)
              downloader.run(image)
            end
            .then do |r|
              spin.update(title: "Downloading of file #{r.id} is finished")
              r
            end
            .rescue { |e| spin.error( "is failed: #{e.message}" ) }
        end

        result = Concurrent.zip(*files).value

        fail Flickrage::DownloadError if spin.error?

        spin.success

        logger.info("Downloaded #{result.compact.size} images:")
        speaker.print_table([PRINT_IMAGE_HEADERS_LITE+%w(path downloaded url)] + result.map{ |i|
          [i.keyword, i.id, i.local_path(opts['output']), i.downloaded?, i.url]
        })

        clean_thread_pool

        image_list.merge_images result
      end
    end

    def resize(image_list)
      logger.debug('Resizing is starting')

      init_crop_value('width')
      init_crop_value('height')

      options = opts.fetch_values(*%w(width height))
      resizer = opts[:resizer].new(*options)

      spinner(message: 'Resizing files') do |spin|
        files = image_list.downloaded.map do |image|
          Concurrent
            .future(thread_pool) { resizer.run(image) }
            .then do |r|
              spin.update(title: "Resizing of file #{r.id} is finished")
              r
            end
            .rescue { |e| spin.error( "is failed: #{e.message}" ) }
        end

        result = Concurrent.zip(*files).value

        fail Flickrage::ResizeError if spin.error?

        spin.success

        logger.info('Resized images:')
        speaker.print_table([PRINT_IMAGE_HEADERS_LITE+%w(path resized)] + result.map{ |i|
          [i.keyword, i.id, i.resize_path(opts['output']), i.resized?]
        })

        clean_thread_pool

        image_list.merge_images result
      end
    end

    def compose(image_list)
      logger.debug('Collage building is starting')

      init_file_name
      options = opts.fetch_values(*%w(file_name width height))
      composer = opts[:composer].new(*options)

      spinner(message: 'Collage making') do |spin|
        composer.run(image_list.resized)
        spin.success
      end
    end

    #
    # Output helpers
    #

    def init_output
      return true if opts['output']

      output = speaker.ask('Please enter the path of the output directory:', path: true)

      unless Dir.exist?(output)
        increment_error_counter(Flickrage::PathError, output)
        init_output
      end

      reset_error_counter

      opts['output'] = output
    end

    def init_file_name
      return true if opts['file_name']
      opts['file_name'] = speaker.ask('Please enter the collage file name:')
    end

    def init_crop_value(name)
      return true if opts[name]

      value = speaker.ask("Please enter image resize #{name}:")
      value = String(value).to_i

      unless value >= MIN_IMAGE_SIZE && value <= MAX_IMAGE_SIZE
        increment_error_counter(Flickrage::NumberError, "#{value} >= #{MIN_IMAGE_SIZE}, #{value} =< #{MAX_IMAGE_SIZE}")
        init_crop_value(name)
      end

      reset_error_counter

      opts[name] = value
    end

    def increment_error_counter(error, value)
      @opts[:ask_error_counter] += 1

      fail error.new(value) if opts[:ask_error_counter] > MAX_ASK_ERRORS
    end

    def reset_error_counter
      @opts[:ask_error_counter] = 0
    end

    def thread_pool
      Flickrage.pool ||= Concurrent::FixedThreadPool.new(Flickrage.config.pool_size)
    end

    def clean_thread_pool
      return unless thread_pool
      thread_pool.kill
      Flickrage.pool = nil
    end
  end
end
