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

      attribute :downloaded, Types::Bool.default(false)
      attribute :resized,    Types::Bool.default(false)

      alias_method :downloaded?, :downloaded
      alias_method :resized?,    :resized

      %w(download resize).each do |m|
        define_method(:"#{m}_finished") do
          self.instance_variable_set(:"@#{m}ed", true)
          self
        end
      end

      def local_path(output)
        File.absolute_path("#{output}/#{file_name}")
      end

      def resize_path(output)
        File.absolute_path("#{output}/#{Flickrage.config.resize_file_prefix}#{file_name}")
      end

      def file_name=(file_name)
        @file_name = file_name
        self
      end
    end
  end
end