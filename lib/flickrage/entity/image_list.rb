module Flickrage
  module Entity
    class ImageList < Dry::Types::Struct
      constructor_type(:schema)

      attribute :images,     Types::Strict::Array.member(Flickrage::Entity::Image).default([])
      attribute :not_founds, Types::Strict::Array.member(Types::Coercible::String).default([])
      attribute :total ,     Types::Int.optional.default(0)
      attribute :composed,   Types::Bool.default(false)
      attribute :collage,    Types::Coercible::String

      alias_method :composed?, :composed

      def downloaded
        images.select(&:downloaded?)
      end

      def resized
        images.select(&:resized?)
      end

      def compose_finished
        @composed = true
        self
      end

      def combine(image_list)
        new_images = images + image_list
        new_total  = new_images.size
        @images = new_images
        @total = new_total
        self
      end

      def clean
        @images = images.compact
        @total  = images.size
        self
      end

      def valid?
        total == Flickrage.config.max
      end

      def has_keys

      end

      def not_founds=(not_founds)
        @not_founds = not_founds
        self
      end

      def merge_images(new_images)
        @images = images | new_images
        self
      end

      def size
        images.size
      end
    end
  end
end