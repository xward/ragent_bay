#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################

module UserApis
  module Mdi
    module Tools

      # @api public
      # A logger. On a production environment, the debug level is discarded.
      # During the development on your VM, everything will be kept.
      class LogClass

        # @api private
        def initialize(apis)
          @user_apis = apis
          if user_api.user_environment['owner'] == 'ragent'
            @head = "Server: "
          else
            @head = "Agent '#{user_api.agent_name}': "
          end
        end

        # @api private
        def user_api
          @user_apis
        end

        # @api public
        # Log low-level details to help debugging your agent during the development.
        # This log level is discarded on the production environment.
        # @params [String] you string to print as debug
        # @example
        #   user_api.mdi.tools.log.debug("my var value = #{var}")
        def debug(str_msg)
          CC.logger.debug("#{@head}#{str_msg}")
        end

        # @api public
        # Log important events that are parts of the normal workflow of your agent.
        # @params [String] you string to print as info
        # @example
        #   user_api.mdi.tools.log.info("start processing my work with message #{msg}")
        def info(str_msg)
          CC.logger.info("#{@head}#{str_msg}")
        end

        # @api public
        # Log unexpected events your agent can recover from.
        # @params [String] you string to print as warn
        #   user_api.mdi.tools.log.info("start processing my work")
        # @example
        #   user_api.mdi.tools.log.warn("I don't think this is normal")
        def warn(str_msg)
          CC.logger.warn("#{@head}#{str_msg}")
        end

        # @api public
        # Log critical events that will prevent your agent from performing its normal processing.
        # @params [String] you string to print as error
        # @example
        #   user_api.mdi.tools.log.warn("The message #{msg} is a zombie terrorist !")
        def error(str_msg)
          CC.logger.error("#{@head}#{str_msg}")
        end

      end

    end
  end
end
