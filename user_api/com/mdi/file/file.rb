require 'net/http'

module UserApis
  module Mdi

    class File

      def initialize(apis)
        @user_apis = apis
      end

      def user_api
        @user_apis
      end

      # Retrieves file contents
      # @param [String] namespace a namespace for the file
      # @param [String] name the file name
      # @return [UserApis::Mdi::File] the last version of the 
      # @raise FileStorageException if an error occured
      def get_file_contents(namespace, name)
        CC::FileStorage.get_file_contents(namespace, name)
      end

      # Retrieves information about the latest version of a file
      # @param [String] namespace a namespace for the file
      # @param [String] name the file name
      # @return [UserApis::Mdi::File::FileInfo] information about the file
      # @api private
      def get_file_information(namespace, name)
        CC::FileStorage.get_file_information(namespace, name)
      end

    end

    class Md5DigestMismatch < StandardException
    end

    class CloudStoreError < StandardException
    end

    # Metadata about a file.
    # @api public
    class FileInfo

      # @return [Integer] the size, in bytes, of the file
      attr_reader :length

      attr_reader :name, :namespace, :description, :md5, :content_type 

      def initialize(opts)
        @name = opts[:name]
        @namespace = opts[:namespace]
        @md5 = opts[:md5]
        @content_type = opts[:contentType]
        if opts[:metadata]
          @description = opts[:metadata][:description]
          @version = opts[:metadata][:version]
        end
      end

    end # class FileInfo

    # A file to be used with MDI Cloud storage API
    # @api public
    class CloudFile

      attr_accessor :file_info

      attr_accessor :contents

      def initialize(opts)
        @file_info = FileInfo.new(opts)
        @contents = Base64.decode64(opts[:contents])
        if(opts[:check_md5])
          md5 = Digest::MD5.digest(@contents)
          if md5 != @file_info.md5
            raise Md5DigestMismatch, "Expected MD5: #{@file_info.md5}, got #{md5}"
          end
        end
      end

    end


  end
end

