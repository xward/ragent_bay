module UserApis
  module Mdi
    module Storage

      # @api private
      class StatsDefinitionsMappingClass

        def initialize(apis)
          @user_apis = apis
          @all_stat_definitions = {}
        end

        def user_api
          @user_apis
        end

        # return a stats definition structs array
        def get_all(account = nil)
          account ||= user_api.account
          @all_stat_definitions[account] ||= RagentApi::StatsDefinitionMapping.get_all(account)
        end

        def get_for_asset_of_type(imei, field_names)
          asset_definitions = []
          definitions = self.get_all

          definitions.each do |definition|
            if (definition['all_assets'] || definition['assets'].include?(imei)) && field_names.include?(definition['field_name'])
              asset_definitions << definition
            end
          end
          asset_definitions
        end
      end

    end #Storage
  end #Mdi
end #UserApis
