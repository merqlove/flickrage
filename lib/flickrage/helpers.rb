# frozen_string_literal: true
require 'tty-spinner'
require 'pastel'

module Flickrage
  # Helpers for main class.
  #
  module Helpers
    module Log
      def logger
        UniversalLogger
      end

      def speaker
        UniversalSpeaker
      end
    end

    module Dict
      def sample_words(n = 1)
        Flickrage.dict.sample(n).map(&:strip)
      end

      def sample_words_strict(n = 1, except: [])
        return [] if Flickrage.dict.size < (n + except.size)
        Flickrage.dict
                 .sample(n + except.size)
                 .map(&:strip)
                  .-(except)
                 .first(n)
      end
    end

    module Tty
      def spinner(message: '', format: :dots)
        options = {
          format: format,
          interval: 20,
          hide_cursor: true,
          success_mark: color(color: :green, message: '+'),
          error_mark: color(color: :red, message: 'x')
        }.merge(Flickrage.config.spinner_options)
        spin = TTY::Spinner.new('[:spinner] :title', options)
        spin.update(title: message)
        Flickrage.config.auto_spin ? spin.auto_spin : spin.start

        return spin unless block_given?

        yield(spin)
      end

      private

      def pastel
        @pastel ||= Pastel.new
      end

      def color(color: :green, message: ' ')
        pastel.send(color, message)
      end
    end

    # UniversalLogger is a module to deal with singleton methods.
    # Used to give classes access only for selected methods
    #
    module UniversalLogger
      %w(debug info warn error fatal unknown).each do |name|
        define_singleton_method(:"#{name}") { |*args, &block| Flickrage.logger.send(:"#{name}", *args, &block) }
      end

      def self.close
        Flickrage.logger.close if Flickrage.logger
      end
    end

    module UniversalSpeaker
      %w(ask yes? no? print_table add_padding).each do |name|
        define_singleton_method(:"#{name}") { |*args| Flickrage.logger.send(:"#{name}", *args) }
      end
    end
  end
end
