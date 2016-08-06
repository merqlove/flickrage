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
    end

    module Tty
      def spinner(message: '', format: :dots, &block)
        spin = TTY::Spinner.new('[:spinner] :title',
                                format: format,
                                success_mark: color(color: :green, message: '+'),
                                error_mark: color(color: :red, message: 'x'))
        spin.update(title: message)

        return spin unless block_given?

        spin.start
        block.call(spin)
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

    # UniversalSpeaker is a module to deal with singleton methods.
    # Used to give classes access only for selected methods
    #
    module UniversalSpeaker
      %w(ask yes? no? print_table).each do |name|
        define_singleton_method(:"#{name}") { |*args| Flickrage.logger.send(:"#{name}", *args) }
      end
    end
  end
end
