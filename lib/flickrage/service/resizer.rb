module Flickrage
  module Service
    class Resizer
      attr_reader :output, :width, :height

      def initialize(width, height)
        @output  = Flickrage.config.output
        @width   = width
        @height  = height
      end

      def run(image)
        image
        image.resize_finished
      rescue
        image
      end

      private

      def file_name(image)
        image.resize_path(output)
      end
    end
  end
end