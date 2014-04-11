#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################

#todo: could be generated
#note(faucon_b): could also use a method_missing proxy and dynamic loading, to avoid code generation
#                while still providing lazy loading

require_relative 'mdi/dialog/dialog'
require_relative 'mdi/geo/geo'
require_relative 'mdi/storage/storage'
require_relative 'mdi/tools/tools'
require_relative 'mdi/file/file'


module UserApis

  # @api public
  # A standard set of API developed by MDI.
  # @note Do not use your custom solution if a suitable APi is already available.
  class MdiClass

    def initialize(apis)
      @user_apis = apis
    end

    def user_api
      @user_apis
    end

    # @api public
    # A set of API for communication with the device or the cloud.
    # @return [Mdi::DialogClass]
    def dialog
      @dialog ||= Mdi::DialogClass.new(user_api)
    end

    # @api public
    # A set of API for geolocalisation tools
    # @return [Mdi::GeoClass]
    def geo
      @geo ||= Mdi::GeoClass.new(user_api)
    end

    # @api public
    # A set of API for storage tools
    # @return [Mdi::StorageClass]
    def storage
      @storage ||= Mdi::StorageClass.new(user_api)
    end

    # @api public
    # Various tools, such as a logger, to help accomplish common tasks.
    # @return [Mdi::ToolsClass]
    def tools
      @tools ||= Mdi::ToolsClass.new(user_api)
    end

    # @api public
    # Read file information or retrieve files from the cloud storage.
    # @return [Mdi::FileManager]
    def file
      @file ||= Mdi::FileManager.new(user_api)
    end

  end
end


module UserApiIncluded

  def mdi
    @mdi ||= UserApis::MdiClass.new(self)
  end

end
