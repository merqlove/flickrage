module Flickrage
  module Service
    class Composer
      attr_reader :output, :file_name, :width, :height

      def initialize(file_name, width, height)
        @output     = Flickrage.config.output
        @file_name  = file_name
        @width      = width
        @height     = height
      end

      def run(images)
        images
        images.compose_finished
      rescue
        images
      end
    end
  end
end