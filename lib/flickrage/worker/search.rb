# frozen_string_literal: true
module Flickrage
  module Worker
    class Search < Base
      include Flickrage::Helpers::Dict

      def call
        keywords = opts['keywords']&.uniq&.first(Flickrage.config.max) || %w()

        speaker.add_padding
        logger.debug('Searching process')
        logger.info("Received keywords: [#{keywords.join(', ')}]")

        keywords += sample_words(Flickrage.config.max - keywords.size)
        keys = keywords.join(', ')

        logger.info("Extended keywords: [#{keys}]")

        @spin = spinner(message: 'Searching ')

        image_list = finder(keywords, spin)

        if image_list.valid?
          spin.success
        else
          spin.error('(not enough images or nothing found)')
          raise Flickrage::SearchError, 'Image list is not valid'
        end

        speaker.add_padding
        logger.info("Found #{image_list.total} images:")
        speaker.print_table([PRINT_IMAGE_HEADERS] + image_list.images.map do |i|
          [i.keyword, i.id, i.url, i.title, i.width, i.height]
        end)

        if Flickrage.config.verbose
          logger.info('Not found keywords:')
          speaker.print_table(image_list.not_founds.map do |word|
            [word]
          end)
        end

        image_list
      ensure
        clean_thread_pool
        spin&.stop
      end

      private

      def time
        @time ||= Time.now.to_i
      end

      def timeout?
        (Time.now.to_i - time) > Flickrage.config.search_timeout
      end

      def service
        @service ||= Service::Search
      end

      def finder(keywords, spin, image_list = nil)
        images = keywords.map do |k|
          Concurrent
            .future(thread_pool) do
              update_spin(spin, title: "Searching (keyword: #{k})")
              service.new.run(k)
            end
            .then do |r|
              update_spin(spin, title: "Searching (found image ID##{r.id})") if r
              r
            end
            .rescue { |_| nil }
        end

        result = Concurrent.zip(*images).value
        result = result.compact.flatten if result

        if image_list
          image_list.combine(result)
          image_list.clean
        else
          image_list = Flickrage::Entity::ImageList.new(images: result,
                                                        total:  result.size)
        end

        return image_list if image_list.valid?

        fail_on_timeout
        success_keywords = result.map(&:keyword)
        not_founds = keywords - success_keywords
        image_list.merge_not_founds(not_founds)

        keywords = sample_words_strict(image_list.estimate, except: image_list.not_founds)
        return image_list if keywords.size.zero?

        finder(keywords, spin, image_list)
      end

      def fail_on_timeout
        raise Flickrage::SystemTimeout if timeout?
      end
    end
  end
end
