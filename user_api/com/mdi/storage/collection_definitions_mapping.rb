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
          @all_definitions ||= RagentApi::CollectionDefinitionMapping.get_all(user_api.account)
        end

        def get_for_asset_with_type(imei, type)
          asset_definitions = []
          definitions = self.get_all()

          definitions.each do |definition|
            if (definition['assets'] == [] || definition['assets'].include?(imei)) && definition['collects'].include?(type)
              asset_definitions << definition
            end
          end
          asset_definitions
        end
      end

    end #Storage
  end #Mdi
end #UserApis
