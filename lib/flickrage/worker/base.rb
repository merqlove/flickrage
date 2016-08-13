# frozen_string_literal: true
require 'concurrent-edge'
require 'mini_magick'

module Flickrage
  module Worker
    class Base
      include Flickrage::Helpers::Log
      include Flickrage::Helpers::Tty

      MAX_ASK_ERRORS = 3

      PRINT_IMAGE_HEADERS_LITE = %w(keyword id).freeze
      PRINT_IMAGE_HEADERS      = PRINT_IMAGE_HEADERS_LITE + %w(url title width height)

      attr_accessor :opts, :service, :spin

      def initialize(opts = {}, service = nil)
        @service = service
        @opts = default_opts.merge(opts)
        @spin = nil
        @opts[:ask_error_counter] = 0
      end

      def call; end

      private

      def default_opts
        {}
      end

      #
      # Output helpers
      #

      def increment_error_counter(error, value)
        @opts[:ask_error_counter] += 1

        return unless opts[:ask_error_counter] >= MAX_ASK_ERRORS
        return yield if block_given?
        raise error, value
      rescue SystemCallError => e
        logger.error(e.message)
        raise error, value
      end

      def reset_error_counter
        @opts[:ask_error_counter] = 0
      end

      #
      # Thread pool access
      #

      def thread_pool
        Flickrage.config.pool ||= Concurrent::FixedThreadPool.new(Flickrage.config.pool_size)
      end

      def clean_thread_pool
        return unless thread_pool
        thread_pool.kill
        Flickrage.config.pool = nil
      end

      #
      # Update spin
      # Due lots of changes in the spinner, keeping wrapper here.
      #

      def update_spin(spin, tags)
        spin.clear_line if opts['force_clear_line']
        spin.update(tags)
        spin.spin if opts['force_spin']
      end
    end
  end
end
