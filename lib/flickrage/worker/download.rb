# frozen_string_literal: true
module Flickrage
  module Worker
    class Download < Base
      def call(image_list)
        raise Flickrage::DownloadError, 'Not enough images for download' if image_list&.size < 1

        speaker.add_padding
        logger.debug('Downloading process')
        logger.info("Scheduled to download #{image_list.size} images")

        init_output

        @spin = spinner(message: 'Downloading')
        files = image_list.images.map do |image|
          Concurrent
            .future(thread_pool) do
              update_spin(spin, title: "Downloading image ID##{image.id}")
              service.run(image)
            end
            .then do |r|
              update_spin(spin, title: "Downloaded image ID##{r.id}")
              r
            end
            .rescue { |_| nil }
        end

        result = Concurrent.zip(*files).value
        result = result.compact.flatten if result

        total = result.count(&:downloaded?)

        if total.positive?
          spin.success
        else
          spin.error('(failed: Not enough images downloaded)')
          raise Flickrage::DownloadError
        end

        speaker.add_padding
        logger.info("Downloaded #{total} images:")
        speaker.print_table([PRINT_IMAGE_HEADERS_LITE + %w(path downloaded?)] + result.map do |i|
          [i.keyword, i.id, i.local_path, i.downloaded?]
        end)

        image_list.merge_images result
      ensure
        clean_thread_pool
        spin&.stop
      end

      private

      def service
        @service ||= Service::Downloader.new
      end

      def init_output
        return if validate_output

        output = speaker.ask('Please enter existing path of the output directory:',
                             path: true)

        if valid_output?(output)
          reset_error_counter

          Flickrage.config.output = output
        end

        increment_error_counter(Flickrage::PathError, output) do
          raise Flickrage::PathError, output unless speaker.yes?("Do you want create path, #{output}?")
          FileUtils.mkdir_p(output)
          Flickrage.config.output = output
        end
        init_output
      end

      def validate_output
        return false unless Flickrage.config.output
        return true if valid_output?(Flickrage.config.output)
        Flickrage.config.output = nil
        false
      end

      def valid_output?(value)
        return false unless value
        Dir.exist?(value)
      end
    end
  end
end
