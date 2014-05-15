#########################################################
# Julien Fouilhé : julien.fouilhe@mobile-devices.fr
# Mobile Devices 2014
#########################################################


module UserApis
  module Mdi
    module Storage

      # @api private
      class CollectionDefinitionsMappingClass

        def initialize(apis)
          @user_apis = apis
        end

        def user_api
          @user_apis
        end

        # return a collection definition structs array
        def get_all()
          RagentApi::CollectionDefinitionMapping.get_all(user_api.account)
        end

      end

    end #Storage
  end #Mdi
end #UserApis
