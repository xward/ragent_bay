#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################


module UserApis
  module Mdi
    module Dialog
      # Track data sent by a device or injected by cloud. Tracks are geolocalised data that can be sent with a optimized format over the wire.
      # @api public
      class TrackClass < Struct.new(:id, :asset, :latitude, :longitude, :recorded_at, :received_at, :fields_data, :account, :meta)

        # @!attribute [rw] id
        #   @api public
        #   @return [String] a unique message ID set by the server.


        # @!attribute [rw] asset
        #   @api public
        #   @return [String] the IMEI or a similar unique identifier of sender of the track data


        # @!attribute [rw] latitude
        #   @api public
        #   @return [Integer] latitude of the asset position when the track was recorded, in degree * 10^-5

        # @!attribute [rw] latitude
        #   @api public
        #   @return [Integer] longitude of the asset position when the track was recorded, in degree * 10^-5

        # @!attribute [rw] recorded_at
        #   @api public
        #   @return [String] when the track was recorded by the device or the provider

        # @!attribute [rw] received_at
        #   @api public
        #   @return [String] when the track was received by the server

        # @!attribute [rw] fields_data
        #   @api public
        #   @return [Array<Hash{String => Object}>] the array of fields collected for this track.
        #                                           A field look like this: `
        #                                           {
        #                                               "name": "GPRMC_VALID",
        #                                               "field": 3,
        #                                               "field_type": "int",
        #                                               "size": 1,
        #                                               "ack": 1,
        #                                               "raw_value": 42,
        #                                               "value":42
        #                                           } `
        #                                           
        # @note You should not use the `raw_value` of the field as it differs between the SDK VM and the real cloud.

        # @!attribute [rw] account
        #   @api public
        #   @return [String] name of the account for this message ("unstable", "municio", ...)

        # @!attribute [rw] meta
        #   @api public
        #   @return [Hash] some metadata for the message, can be nil.

        def initialize(apis, struct = nil)
          @user_apis = apis

          if struct.blank?
            self.meta = {}

          else
            self.meta = struct['meta']
            payload = struct['payload']

            self.id = payload['id']
            self.asset = payload['asset']
            self.account = self.meta['account']

            self.latitude = payload['latitude'].to_i
            self.longitude = payload['longitude'].to_i
            self.recorded_at = payload['recorded_at']
            self.received_at = payload['received_at']

            self.fields_data = []
            payload.each do |k, v|
              field = apis.mdi.storage.tracking_fields_info.get_by_id(k, true)
              next if field == nil
              RAGENT.api.mdi.tools.log.debug("init track with track gives #{k} #{v} #{field}")
              field['raw_value'] = v
              field['value'] = v
              field['fresh'] = false

              # decode if Ragent. In VM mode, raw_value = value, nothing else to do
              # Note that the raw_value is thus different between VM mode and Ragent.
              if RAGENT.running_env_name == 'ragent'
                # basic decode
                case field['field_type']
                when 'integer'
                  field['value'] = v.to_s.unpack('B*').first.to_i(2)
                when 'string'
                  field['value'] = v.to_s
                when 'boolean'
                  field['value'] = v.to_s == "\x01" ? true : false
                end
              end
              #idea: metric for pos, speed

              self.fields_data << field
            end


          end

        end

        # @api private
        def user_api
          @user_apis
        end

        # @return [Hash] a hash representation of this event. See constructor documentation for the format.
        # @api private
        def to_hash(without_fields = false)
          r_hash = {}
          r_hash['meta'] = self.meta
          r_hash['payload'] = {
            'id' => self.id,
            'asset' => self.asset,
            'recorded_at' => self.recorded_at,
            'received_at' => self.received_at,
            'latitude' => self.latitude,
            'longitude' => self.longitude
          }
          if !without_fields
            #add field of new data (and convert it as magic string)
            self.fields_data.each do |field|
              CC.logger.debug("to_hash: Adding field '#{field['field']}' with val= #{field['value']}")
              r_hash['payload'][field['field']] = "#{field['value']}"
            end
          end

          r_hash['meta'].delete_if { |k, v| v.nil? }
          r_hash['payload'].delete_if { |k, v| v.nil? }
          r_hash
        end

        # @return [Hash] a hash representation of this event in the format to be sent to the cloud (data injection)
        # @api private
        def to_hash_to_send_to_cloud
          r_hash = {}
          r_hash['meta'] = {
            'account' => self.account
          }
          r_hash['payload'] = {
            'id' => CC.indigen_next_id(self.asset),
            'sender' => 'ragent', # todo: add in model of db viewer (todo)
            'asset' => self.asset,
            'received_at' => Time.now.to_i,
            'recorded_at' => self.recorded_at == nil ? Time.now.to_i : self.recorded_at,
            'latitude' => self.latitude,
            'longitude' => self.longitude
          }

          #add  fresh field of new data (and convert it as magic string)
          self.fields_data.each do |field|
            if field['fresh']
               CC.logger.debug("to_hash_to_send_to_cloud: Adding field '#{field['field']}' with val= #{field['value']}")
              r_hash['payload']["#{field['field']}"] = "#{field['raw_value']}"
            end
          end

          r_hash['meta'].delete_if { |k, v| v.nil? }
          r_hash['payload'].delete_if { |k, v| v.nil? and k != 'latitude' and k != 'longitude'}
          r_hash
        end

        def set_field(name, value)
          field = user_api.mdi.storage.tracking_fields_info.get_by_name(name, self.account)
          return self.fields_data if field == nil
          field['raw_value'] = value
          field['value'] = value
          field['fresh'] = true
          self.fields_data << field
          self.recorded_at = Time.now.to_i
        end


      end #Track
    end #Dialog
  end #Mdi
end #UserApis


