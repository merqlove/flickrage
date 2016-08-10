# frozen_string_literal: true
module Flickrage
  module Service
    class Search
      include Flickrage::Helpers::Log

      FLICKR_SIZES = %w(l o c z m)

      attr_reader :tagged_search, :search_params

      def initialize
        @tagged_search = Flickrage.config.tagged_search
        @search_params = Flickrage.config.search_params
      end

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
        size = get_image_size(result)
        return unless size

        Flickrage::Entity::Image.new(
          id:      result.id,
          title:   title(result.title),
          keyword: keyword,
          url:     result.send(:"url_#{size}"),
          width:   result.send(:"width_#{size}"),
          height:  result.send(:"height_#{size}"),
        )
      end

      def search(keyword)
        flickr.photos.search(params(search_query(keyword)))
      end

      def title(text)
        return text if text.nil? || text.size < 50
        text[0..50] + '...'
      end

      def get_image_size(result)
        FLICKR_SIZES.detect { |t| result.respond_to?(:"url_#{t}") }
      end

      def params(opts = {})
        {
          extras: 'url_m, url_z, url_c, url_l, url_o',
          sort: 'interestingness-desc',
          per_page: 1,
          pages: 1,
          media: 'photos',
          accuracy: 1
        }.merge(opts).merge(search_params)
      end

      def search_query(keyword)
        tagged_search ? {tags: [keyword]} : {text: keyword}
      end
    end
  end
end
