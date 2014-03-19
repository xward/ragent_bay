#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2014
#########################################################

module UserApis
  module Mdi
    module Geo
      # A generic subscriber class tool
      class NavServerClass

        def initialize(apis = nil)
          @user_apis = apis
        end

        def user_api
          @user_apis
        end

        def get_query(service_url_suffix)
          CC::NavServer.get_query(service_url_suffix)
        end

      end

    end
  end
end
