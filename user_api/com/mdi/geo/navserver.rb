#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2014
#########################################################

module UserApis
  module Mdi
    module Geo

      # @api private
      # A generic subscriber class tool
      class NavServerClass

        def initialize(apis = nil)
          @user_apis = apis
        end

        def user_api
          @user_apis
        end

        # query the navserver
        # @params [String] service_url_suffix service to use with parameters
        def get_query(service_url_suffix)
          CC::NavServer.get_query(service_url_suffix)
        end

        def post_query(service_url_suffix, body)
          CC::NavServer.post_query(service_url_suffix, body)
        end

      end

    end
  end
end
