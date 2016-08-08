# frozen_string_literal: true
require 'uri'
require 'net/http'

module Flickrage
  module Service
    class Downloader
      include Flickrage::Helpers::Log

      def run(image)
        uri = gen_uri(image.url)
        image.file_name = file_name(uri)
        download_file(uri, image.local_path)
        check_image(image)
      rescue StandardError => e
        logger.debug(e)
        image
      end

      private

      def download_file(uri, path, limit = 10)
        raise Flickrage::DownloadError, 'Redirect limit arrived' if limit.zero?

        Net::HTTP.start(uri.host, uri.port,
                        use_ssl: uri.scheme == 'https') do |conn|
          request = Net::HTTP::Get.new(uri)
          response = conn.request request

          case response
          when Net::HTTPSuccess
            write_file(path, response.body)
          when Net::HTTPRedirection
            download_file(gen_uri(response['location']),
                          path,
                          limit - 1)
          else
            response.error!
          end
        end
      end

      def write_file(path, body, mode = 'wb')
        File.open(path, mode) do |file|
          file.flock(File::LOCK_EX)
          file << body
        end
      end

      def gen_uri(url)
        URI.parse(url)
      end

      def file_name(uri)
        File.basename(uri.path)
      end

      def check_image(image)
        File.exist?(image.local_path) ? image.finish_download : image
      end
    end
  end
end
