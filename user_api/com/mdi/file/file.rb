require 'net/http'

module UserApis
  module Mdi

    # @api public
    # Grants access to the cloud file storage.
    #
    # In VM mode (using the SDK), files are stored in the filesystem.
    # In a real production environment, the files are stored in a database and served via HTTP. Thus retrieving a file is a significantly
    # longer operation in a production environement (could take a second or so even for a small file) than in your VM.
    #
    # *The provided methods do not perform any caching of the results*. It is up to you to cache the information you need.
    # You should always cache as much as possible as retrieving a file is an expensive operation.
    #
    # A file (see {CloudFile}) has a name and a namespace. In VM mode, the file "example/some_data" will be stored in a `example` folder in
    # the `file_storage` folder of your workspace under the filename "example". Additionally, a file named "example.metadata.json" will
    # hold the metadata of this file (it is simply a hash representation of a {FileInfo} object).
    #
    # An agent does not have direct access to the filesystem in production mode (neither in read or write more).
    # Even if this is not acutally enforced in the SDK, do not rely on accessing the filesystem.
    #
    # The {TestsHelper} module exposes some methods to create and delete files for use in your tests
    # with less constraints than the methods provided here. For static configuration files, consider
    # `user_api.mdi.storage.config`.
    #
    # @todo: allow the agent to store a file itself
    class FileManager

      # @api private
      def initialize(apis)
        @user_apis = apis
      end

      # @api private
      def user_api
        @user_apis
      end

      # @api public
      def new_file(opts)
        CloudFile.new(user_api, opts)
      end

      # Retrieves file contents.
      # @param [String] namespace a namespace for the file
      # @param [String] name the file name
      # @return [String] the latest version of the file (binary contents), or nil if no suitable file has been found
      # @raise [FileStorageError] if an error occured when retrieving file information
      # @api public
      def get_file_contents(namespace, name)
        CC::FileStorage.get_file_contents(namespace, name)
      end

      # Retrieves information about the latest version of a file
      # @param [String] namespace a namespace for the file
      # @param [String] name the file name
      # @return [FileInfo] information about the file, or nil if no suitable file has been found
      # @raise [FileStorageError] if an error occured when retrieving file information
      # @api public
      def get_file_information(namespace, name)
        CC::FileStorage.get_file_information(namespace, name)
      end

      # Retrieves in one call the file and its metadata.
      # @param [String] namespace a namespace for the file
      # @param [String] name the file name
      # @return [CloudFile] information about the file, or nil if no suitable file has been found
      # @raise [FileStorageError] if an error occured when retrieving file information
      # @api public
      def get_file(namespace, name)
        CC::FileStorage.get_file(namespace, name)
      end

    end

    class Md5DigestMismatch < StandardError
    end

    # @api public
    class FileStorageError < StandardError
    end

    # @api public
    class FileNotFoundError < FileStorageError
    end

    # Metadata about a file.
    # @api public
    class FileInfo

      # @api public
      # @return [Integer] the size, in bytes, of the file
      attr_reader :length

      # @api public
      # @return [String] the name of the file
      attr_reader :name

      # @api public
      # @return [String] namespace for the file
      attr_reader :namespace

      # @api public
      # @return [String] the file description
      attr_reader :description

      # @api public
      # @return [String] a hex representation of the file MD5.
      attr_reader :md5

      # @api public
      # @return [String] a MIME type for this file. Note that the MIME type is not always known and default to `binary/octet-stream`
      attr_reader :content_type

      # @param [Hash] opts a parameters hash
      # @options opts [String] :name name of the file
      # @options opts [String] :namespace namespace for the file
      # @options opts [String] :md5 a hexadecimal representation of the MD5 checksum of the file
      # @options opts [Hash] :metadata optional metadata for the file. The possible keys are :description and :version.
      # @options opts [String] :content_type MIME type of the file. Default to `binary/octet-stream`
      # @api public
      def initialize(opts)
        @name = opts[:name]
        @namespace = opts[:namespace]
        @md5 = opts[:md5]
        @content_type = opts[:content_type]
        if opts[:metadata]
          @description = opts[:metadata][:description]
          @version = opts[:metadata][:version]
        end
      end

      # @api private
      def to_hash
        {
          name: @name,
          namespace: @namespace,
          md5: @md5,
          content_type: @content_type,
          metadata: {
            description: @description,
            version: @version
          }
        }
      end

      # @api private
      def to_json
        to_hash.to_json
      end

    end # class FileInfo

    # A file to be used with the MDI Cloud storage API
    # @api public
    class CloudFile

      # @api public
      # @return [FileInfo] file information
      attr_accessor :file_info

      # @api public
      # @return [String] file contents (the returned string encoding should not be used to understand the file contents - treat the result as raw binary data)
      attr_accessor :contents

      # @param [Hash] opts a parameter hash. Supports the same parameters as {FileInfo#new} plus a mandatory :contents key with the contents of the file.
      #               If the optional parameter :check_md5 is set to true, the constructor will check the MD5 of the contents
      # @api public
      def initialize(opts)
        @file_info = FileInfo.new(opts)
        @contents = opts[:contents]
        if(opts[:check_md5])
          md5 = Digest::MD5.hexdigest(@contents)
          if md5 != @file_info.md5
            raise Md5DigestMismatch, "Expected MD5: #{@file_info.md5}, got #{md5}"
          end
        end
      end

    end


  end
end

