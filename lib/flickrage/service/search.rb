# frozen_string_literal: true
module Flickrage
  module Service
    class Search
      include Flickrage::Helpers::Log

      def run(keyword)
        result = search(keyword)

        return if result.size < 1

        image(result.first, keyword)
      rescue StandardError => e
        logger.debug(e)
        nil
      end

      private

      def image(result, keyword)
        return unless result.respond_to?(:url_l)

        Flickrage::Entity::Image.new(
          id:      result.id,
          title:   title(result.title),
          keyword: keyword,
          url:     result.url_l,
          width:   result.width_l,
          height:  result.height_l,
        )
      end

      def search(keyword)
        flickr.photos.search(params(text: keyword))
      end

      def title(text)
        return text if text.nil? || text.size < 50
        text[0..50] + '...'
      end

      def params(opts = {})
        {
          content_type: '1',
          extras: 'url_l',
          sort: 'interestingness-desc',
          per_page: 1,
          pages: 1
        }.merge(opts)
      end
    end
  end
end
