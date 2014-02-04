#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2014
#########################################################


module UserApis
  module Mdi
    module Dialog
      # A class that represents a standard collection
      class CollectionClass < Struct.new(:data)

        def initialize(apis, struct = nil)

          @user_apis = apis

          if struct.blank?
            self.data = {}
          else
            self.data = struct['data']
          end
        end

        def user_api
          @user_apis
        end

        def to_hash
          r_hash = {}

          r_hash
        end

        def fast_push
          CC.push(self.to_hash)
        end

      end #Message
    end #Dialog
  end #Mdi
end #UserApis
