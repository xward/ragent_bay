#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2014
#########################################################

require_relative 'navserver'

module UserApis
  module Mdi

    # @api private
    class GeoClass

      def initialize(apis)
        @user_apis = apis
      end

      def user_api
        @user_apis
      end

      def navserver
        @navserver ||= Geo::NavServerClass.new(user_api)
      end

    end

  end
end
