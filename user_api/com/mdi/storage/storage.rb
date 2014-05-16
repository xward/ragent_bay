#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################

require_relative 'tracking_field_mapping'
require_relative 'collection_definitions_mapping'

module UserApis
  module Mdi

    # @api public
    class StorageClass

      # @api private
      def initialize(apis)
        @user_apis = apis
      end

      # @api private
      def user_api
        @user_apis
      end

      # This is your redis cache.
      # @note Rememeber that it can be deleted at anymoment, and you don't share this cache with other instance of your agent in the cloud.
      # @param [String] you can specify a namespace to use different redis object.
      # @example
      #   user_api.mdi.storage.redis['last operation'] = Time.now
      #   user_api.mdi.storage.redis.hget("fuelNames", local)
      #   listjson = user_api.mdi.storage.redis.zrangebyscore(key, elem1, elem2)
      # @see http://redis.io/commands for more details about available commands.
      def redis(id = 'default')
        @user_redis ||= {}
        @user_redis[id] ||= Redis::Namespace.new("RR:#{user_api.agent_name}_#{id}", :redis => CC.redis)
      end


      # @api_private
      def tracking_fields_info
        @tracking_fields_info ||= Storage::TrackFieldMappingClass.new(user_api)
      end

      # @api_private
      def collections_definitions
        @collection_definitions ||= Storage::CollectionDefinitionsMappingClass.new(user_api)
      end

      # This is where your configuration is stored (setted in config/your_agent.yml)
      def config
        @config ||= user_api.user_class.user_config
      end

      # @api_private
      def agent_root_path
        user_api.user_class.root_path
      end

    end

  end
end
