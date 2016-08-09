# frozen_string_literal: true
module Flickrage
  module Worker
    class Compose < Base
      def call(image_list)
        raise Flickrage::CollageError, 'Not enough images for collage' if image_list.resized&.size < 1

        speaker.add_padding
        logger.debug('Collage building process')

        image_list.collage_path = init_file_name

        @spin = spinner(message: 'Collage making')
        result = service.run(image_list)

        if result.composed?
          spin.success
        else
          spin.error('(failed: Collage was not made)')
          raise Flickrage::CollageError
        end

        result
      ensure
        spin&.stop
      end

      private

      def service
        @service ||= Service::Composer.new(opts['file_name'],
                                         Flickrage.config.width,
                                         Flickrage.config.height)
      end

      def init_file_name
        return opts['file_name'] if validate_file_name

        output = speaker.ask('Please enter the collage file name:', path: true)

        unless valid_file_name?(output)
          increment_error_counter(Flickrage::FileNameError,
                                  "#{output}, must be valid, supported extensions: .png, .jpg or .gif")
          return init_file_name
        end

        reset_error_counter

        opts['file_name'] = output
      end

      def validate_file_name
        return false unless opts['file_name']
        return true if valid_file_name?(opts['file_name'])
        opts['file_name'] = nil
        false
      end

      def valid_file_name?(value)
        return false unless value
        value.match(/^([a-zA-Z0-9\-_\.]+)\.(png|jpg|jpeg|gif)$/)
      end
    end
  end
end
