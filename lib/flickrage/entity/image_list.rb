# frozen_string_literal: true
module Flickrage
  module Entity
    class ImageList < Dry::Types::Struct
      constructor_type(:schema)

      attribute :images,       Types::Strict::Array.member(Flickrage::Entity::Image).default([])
      attribute :not_founds,   Types::Strict::Array.member(Types::Coercible::String).default([])
      attribute :total,        Types::Int.optional.default(0)
      attribute :compose,      Types::Bool.default(false)
      attribute :collage_path, Types::Coercible::String

      alias composed? compose

      def downloaded
        images.select(&:downloaded?)
      end

      def resized
        images.select(&:resized?)
      end

      def finish_compose
        @compose = true
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

      def merge_not_founds(new_not_founds)
        @not_founds = not_founds + new_not_founds
        self
      end

      def merge_images(new_images)
        @images = images | new_images
        self
      end

      def size
        images.size
      end

      def collage_path=(file_name = nil)
        file_name = "collage.#{Time.now.to_i}.jpg" if file_name.nil?
        @collage_path = File.absolute_path("#{Flickrage.config.output}/#{file_name}")
      end
    end
  end
end
