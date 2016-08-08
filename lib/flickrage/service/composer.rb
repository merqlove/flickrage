# frozen_string_literal: true
module Flickrage
  module Service
    class Composer
      include Flickrage::Helpers::Log

      attr_reader :file_name, :width, :height, :shuffle

      def initialize(file_name, width, height, shuffle: true)
        @file_name = file_name
        @width     = width
        @height    = height
        @shuffle   = shuffle
      end

      def run(image_list)
        compose(image_list)
        check_image(image_list)
      rescue StandardError => e
        logger.debug(e)
        image_list
      end

      private

      def compose(image_list)
        montage = MiniMagick::Tool::Montage.new
        images(image_list.resized).each { |image| montage << image.resize_path }

        montage_width  = width * (image_list.resized.size / Flickrage.config.grid).to_i
        montage_height = height * Flickrage.config.grid

        montage.geometry   "#{montage_width}x#{montage_height}+0+0"
        montage.tile       "x#{Flickrage.config.grid}"
        montage.mode       'Concatenate'
        montage.background 'none'

        montage << image_list.collage_path
        montage.call
      end

      def images(images)
        shuffle ? images.shuffle : images
      end

      def check_image(image_list)
        File.exist?(image_list.collage_path) ? image_list.finish_compose : image_list
      end
    end
  end
end
