# frozen_string_literal: true
require 'concurrent-edge'

module Flickrage
  class Pipeline
    include Flickrage::Helpers::Log

    attr_reader :opts

    def initialize(opts = {})
      @opts = opts
    end

    #
    # Main pipeline
    #

    def run
      logger.warn('Thank you for choosing Flickrage, you will find me as your Flickr collage companion :)')

      list = Concurrent
        .future { search_worker.call }
        .then { |image_list| download_worker.call(image_list) }
        .then { |image_list| resize_worker.call(image_list) }
        .then { |image_list| compose_worker.call(image_list) }
        .then do |image_list|
          logger.info("#{image_list&.size || 0} images composed")
          image_list
        end
        .rescue { |e| logger.error(e) }
        .wait.value

      speaker.add_padding

      raise Flickrage::CollageError, 'Try again later...' unless valid_list?(list)

      logger.warn("Congrats! You can find composed collage at #{list.collage_path}")

      list
    end

    private

    def search_worker
      @search_worker ||= opts[:search_worker] || Worker::Search.new(opts)
    end

    def download_worker
      @download_worker ||= opts[:download_worker] || Worker::Download.new(opts)
    end

    def resize_worker
      @resize_worker ||= opts[:resize_worker] || Worker::Resize.new(opts)
    end

    def compose_worker
      @compose_worker ||= opts[:compose_worker] || Worker::Compose.new(opts)
    end

    def valid_list?(list)
      list.respond_to?(:valid?) && list.valid?
    end
  end
end
