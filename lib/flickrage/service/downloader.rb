# frozen_string_literal: true
require 'uri'
require 'net/http'

module Flickrage
  module Service
    class Downloader
      include Flickrage::Helpers::Log

      def run(image)
        uri = gen_uri(image.url)
        image.file_name = file_name(uri) unless image.file_name
        download_file(uri, image.local_path)
        check_image(image)
      rescue StandardError => e
        logger.debug(e)
        image
      end

      private

      def download_file(uri, path, mode = 'wb')
        File.open(path, mode) do |file|
          file.flock(File::LOCK_EX)
          parse_file(uri, file)
        end
      ensure
        FileUtils.rm_f(path) if File.size(path).zero?
      end

      def parse_file(uri, file, limit = Flickrage.config.download_timeout)
        raise Flickrage::DownloadError, 'Redirect limit arrived' if limit.zero?

        Net::HTTP.start(uri.host, uri.port,
                        use_ssl: uri.scheme == 'https') do |conn|
          conn.request_get(uri.path) do |response|
            case response
            when Net::HTTPSuccess
              response.read_body do |seg|
                file << seg
              end
            when Net::HTTPRedirection
              download_file(gen_uri(response['location']),
                            path,
                            limit - 1)
            else
              response.error!
            end
          end
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
