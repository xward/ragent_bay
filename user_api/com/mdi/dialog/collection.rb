#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2014
#########################################################


module UserApis
  module Mdi
    module Dialog
      # A class that represents a standard collection
      class CollectionClass < Struct.new(:name, :type, :meta, :account, :id, :asset, :start_at, :stop_at, :presences, :tracks, :messages)

        def initialize(apis, struct = nil)

          @user_apis = apis

          self.type = 'collection'

          if struct.blank?
            self.name = 'unknown'
            self.meta = {}
            self.account = ''
            self.id = -1
            self.asset = ''
            self.start_at = 0
            self.stop_at = 0
            self.presences = []
            self.messages = []
            self.tracks = []
          else
            self.meta = struct['meta']
            payload = struct['payload']

            self.name = 'unknown'
            self.account = self.meta['account']
            self.id = payload['id']
            self.asset = payload['asset']
            self.start_at = payload['start_at'].to_i
            self.stop_at = payload['stop_at'].to_i
            self.presences = payload['presences']
            self.messages = payload['messages']
            self.tracks = payload['tracks']
          end
        end

        def user_api
          @user_apis
        end


 # ex
 #{"meta":{"account":"unstable"},"payload":{"id":561902626124333056,"id_str":"561902626124333056","asset":"FAKE0000001635","name":"My trips","start_at":1974,"stop_at":1974,
 # "tracks":[{"id":"545648584880832729","asset":"kikoo","recorded_at":134567865,"recorded_at_ms":134567865,"received_at":5678545,"longitude":"236561.0","latitude":"4896980.0","14":"MQ=="}]}}

        def to_hash
          r_hash = {}

          r_hash['meta'] = self.meta
          r_hash['meta'] = {} if r_hash['meta'] == nil
          r_hash['meta']['account'] = self.account
          r_hash['payload'] = {

            'id' => self.id,
            'asset' => self.asset,
            'name' => self.name,
            'start_at' => self.start_at,
            'start_at' => self.start_at,
            'presences' => self.presences,
            'messages' => self.messages,
            'tracks' => self.tracks,
          }
          r_hash['meta'].delete_if { |k, v| v.nil? }
          r_hash['payload'].delete_if { |k, v| v.nil? }


          r_hash
        end

      end #Collection
    end #Dialog
  end #Mdi
end #UserApis
