require 'uri'
require 'open-uri'

module Flickrage
  module Service
    class Downloader
      attr_reader :output

      def initialize(*)
        @output = Flickrage.config.output
      end

      def run(image)
        image.file_name = file_name(image.url)
        download_file(image.url, image.local_path(output))
        image.download_finished
      rescue => _
        image
      end

      private

      def download_file(url, path)
        File.open(path, 'wb') do |f|
          f.flock(File::LOCK_EX)
          f << open(url).read
        end
      end

      def file_name(url)
        uri = URI.parse(url)
        File.basename(uri.path)
      end
    end
  end
end