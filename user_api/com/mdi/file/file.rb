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

      # @param [Hash] opts a parameters hash 
      # @options opts [String] :name name of the file
      # @options opts [String] :namespace namespace for the file
      # @options opts [String] :md5 a hexadecimal representation of the MD5 checksum of the file
      # @options opts [Hash] :metadata optional metadata for the file. The possible keys are :description and :version.
      # @options opts [String] :contentType MIME type of the file. Note that the MIME type is not always known and default to `binary/octet-stream`
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

      # @param [Hash] opts a parameter hash. Supports the same parameters as {FileInfo#new} plus a mandatory :contents key with the Base64-encoded contents of the file.
      #               If the optional parameter :check_md5 is set to true, the constructor will check the MD5 of the contents 
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

