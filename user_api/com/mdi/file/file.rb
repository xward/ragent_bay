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
    class FileManager

      attr_reader :user_apis

      # @api private
      def initialize(apis)
        @user_apis = apis
      end

      # @api public
      def new_file(opts)
        CloudFile.new(user_api, opts)
      end

      # Retrieves information about the latest version of a file
      # @param [String] namespace a namespace for the file
      # @param [String] name the file name
      # @param [String] account the name of the account of the device which requested the file
      # @param [String] asset asset of the device which requested the file
      # @return [FileInfo] information about the file, or nil if no suitable file has been found
      # @raise [FileStorageError] if an error occured when retrieving file information
      # @api public
      def get_file_info(namespace, name, account, asset)
        CC::FileStorage.get_file_information(namespace, name, account, asset)
      end

      # Retrieves in one call the file and its metadata.
      # @param [String] namespace a namespace for the file
      # @param [String] name the file name
      # @param [String] account the name of the account of the device which requested the file
      # @param [String] asset asset of the device which requested the file
      # @return [CloudFile] information about the file, or nil if no suitable file has been found
      # @raise [FileStorageError] if an error occured when retrieving file information
      # @api public
      def get_file(namespace, name, account, asset)
        CC::FileStorage.get_file(namespace, name, account, asset)
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

    class Unauthorized < FileStorageError
    end

    # A role, associated to a whole account or a device, which is known to provide read access to a file.
    class ReadAccessRole

      # @return [String] the name of the role
      attr_accessor :name

      # @return [Array<String>] assets that have this role
      attr_accessor :assets

      # @return [Array<String>] accounts whose all assets have this role
      attr_accessor :accounts

      # Create a new role with associated devices and accounts
      # @param [Hash] opts parameters hash
      # @option opts [String] :name name of the role
      # @option opts [Array<String>] :assets assets that have this role
      # @option opts [Array<String>] :accounts accounts that have this role
      def initialize(opts)
        @name = opts[:name]
        @assets = opts[:assets] || []
        @accounts = opts[:accounts] || []
      end

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

      # @return [Array<ReadAccessRole>] roles that are known to provide read access to this file
      attr_accessor :roles

      # @param [Hash] opts a parameters hash
      # @options opts [String] :name name of the file
      # @options opts [String] :namespace namespace for the file
      # @options opts [String] :md5 a hexadecimal representation of the MD5 checksum of the file
      # @options opts [Hash] :metadata optional metadata for the file. The possible keys are :description and :version.
      # @options opts [String] :content_type MIME type of the file. Default to `binary/octet-stream`
      # @options opts [Array<ReadAccessRole>] roles :roles that are known to provide read access to this file. Default to an empty array.
      # @api public
      def initialize(opts)
        raise ArgumentError, "File name must not be nil" unless opts[:name]
        @name = opts[:name]
        raise ArgumentError, "Namespace must not be nil" unless opts[:namespace]
        @namespace = opts[:namespace]
        raise ArgumentError, "MD5 must not be nil" unless opts[:md5]
        @md5 = opts[:md5]
        @content_type = opts[:content_type] || "binary/octet-steam"
        if opts[:metadata]
          @description = opts[:metadata][:description]
          @version = opts[:metadata][:version]
        end
        @roles = opts[:roles] || []
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
      # @return [String] file contents (the returned string encoding should not be used to understand the file contents
      #                  treat the result as raw binary data)
      attr_accessor :contents

      # @param [Hash] opts a parameter hash.
      # @option opts [FileInfo] :file_info metadata for this file
      # @option opts [Boolean] :check_md5 if set to true, the constructor will check the MD5 of the contents.
      # @option opts [String] :contents binary contents of the file
      # @api public
      def initialize(opts)
        @file_info = opts[:file_info]
        @contents = opts[:contents]
        if opts[:check_md5]
          md5 = Digest::MD5.hexdigest(@contents)
          if md5 != @file_info.md5
            raise Md5DigestMismatch.new("Expected MD5: #{@file_info.md5}, got #{md5}")
          end
        end
      end

    end

  end
end
