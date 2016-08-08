# frozen_string_literal: true
module Flickrage
  module Service
    class Resizer
      include Flickrage::Helpers::Log

      attr_reader :width, :height

      def initialize(width, height)
        @width  = width
        @height = height
      end

      def run(image)
        return image unless image.downloaded?
        resize_to_fill(image)
        check_image(image)
      rescue => e
        logger.debug(e)
        image
      end

      private

      def resize_to_fill(image, gravity = 'Center')
        img = MiniMagick::Image.open(image.local_path)

        cols, rows = img[:dimensions]
        img.combine_options do |cmd|
          if width != cols || height != rows
            scale_x = width / cols.to_f
            scale_y = height / rows.to_f
            if scale_x >= scale_y
              cols = (scale_x * (cols + 0.5)).round
              rows = (scale_x * (rows + 0.5)).round
              cmd.resize cols.to_s
            else
              cols = (scale_y * (cols + 0.5)).round
              rows = (scale_y * (rows + 0.5)).round
              cmd.resize "x#{rows}"
            end
          end
          cmd.gravity gravity
          cmd.background 'rgba(255,255,255,0.0)'
          cmd.extent ">#{width}x#{height}" if cols != width || rows != height
        end
        img.write image.resize_path
      end

      def file_name(image)
        image.resize_path
      end

      def check_image(image)
        File.exist?(image.resize_path) ? image.finish_resize : image
      end
    end
  end
end
