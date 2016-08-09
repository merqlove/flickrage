# frozen_string_literal: true
module Flickrage
  module Worker
    class Resize < Base
      MIN_IMAGE_SIZE = 100
      MAX_IMAGE_SIZE = 1000

      def call(image_list)
        raise Flickrage::ResizeError, 'Not enough images for resize' if image_list.downloaded&.size < 1

        speaker.add_padding
        logger.debug('Resizing process')

        init_crop_value('width')
        init_crop_value('height')

        @spin = spinner(message: 'Resizing images')
        files = image_list.downloaded.map do |image|
          Concurrent
            .future(thread_pool) do
              update_spin(spin, title: "Resizing image #{image.id}")
              service.run(image)
            end
            .then do |r|
              update_spin(spin, title: "Resized image #{r.id}")
              r
            end
            .rescue { |_| nil }
        end

        result = Concurrent.zip(*files).value
        result = result.compact.flatten if result

        total = result.count(&:resized?)

        if total > 2
          spin.success
        else
          spin.error('(failed: Not enough images resized)')
          raise Flickrage::ResizeError
        end

        speaker.add_padding
        logger.info("Resized #{result.count(&:resized?)} images:")
        speaker.print_table([PRINT_IMAGE_HEADERS_LITE + %w(path resized?)] + result.map do |i|
          [i.keyword, i.id, i.resize_path, i.resized?]
        end)

        image_list.merge_images result
      ensure
        clean_thread_pool
        spin&.stop
      end

      private

      def service
        @service ||= Service::Resizer.new(Flickrage.config.width, Flickrage.config.height)
      end

      def init_crop_value(name)
        return true if valid_value?(Flickrage.config[name])

        value = speaker.ask("Please enter image resize #{name}:")
        value = String(value).to_i

        unless valid_value?(value)
          increment_error_counter(Flickrage::NumberError,
                                  "#{value} >= #{MIN_IMAGE_SIZE}, #{value} =< #{MAX_IMAGE_SIZE}")
          return init_crop_value(name)
        end

        reset_error_counter

        Flickrage.config[name] = value
      end

      def valid_value?(value)
        return false unless value
        value >= MIN_IMAGE_SIZE && value <= MAX_IMAGE_SIZE
      end
    end
  end
end
