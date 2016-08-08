# frozen_string_literal: true
module Flickrage
  module Entity
    class Image < Dry::Types::Struct
      constructor_type(:schema)

      attribute :id,        Types::Coercible::Int
      attribute :title,     Types::Coercible::String
      attribute :keyword,   Types::Coercible::String
      attribute :url,       Types::Coercible::String
      attribute :file_name, Types::Coercible::String
      attribute :width,     Types::Coercible::Int
      attribute :height,    Types::Coercible::Int

      attribute :download,  Types::Bool.default(false)
      attribute :resize,    Types::Bool.default(false)

      alias downloaded? download
      alias resized? resize

      %w(download resize).each do |m|
        define_method(:"finish_#{m}") do
          instance_variable_set(:"@#{m}", true)
          self
        end
      end

      def local_path
        File.absolute_path("#{Flickrage.config.output}/#{file_name}")
      end

      def resize_path
        File.absolute_path("#{Flickrage.config.output}/#{Flickrage.config.resize_file_prefix}#{file_name}")
      end

      def file_name=(file_name)
        @file_name = file_name
        self
      end
    end
  end
end
