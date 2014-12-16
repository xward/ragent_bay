#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################

module RagentApi
  module TrackFieldMapping

    def self.invalid_map
      @mapping_track_field_number = nil
    end

    def self.fetch_default_map
      @default_track_field_info ||= begin
        vm_json_path = '/home/vagrant/ruby-agents-sdk/cloud_configuration/default_tracks_field_info.json'
        if File.exists?(vm_json_path)
          CC.logger.info("fetch_default_map from vm path")
          JSON.parse(File.read(vm_json_path))
        else
          if RAGENT.running_env_name == 'sdk-vm'
            PUNK.start('track load')
            CC.logger.warn("track field file not found: #{vm_json_path}")
            CC.logger.warn("It is normal if you are not into the vagrant vm")
            PUNK.end('track load','warn','notif',"Track config failover")
          end
          path = File.expand_path("..", __FILE__)
          CC.logger.info("fetch_default_map from local")
          JSON.parse(File.read("#{path}/default_tracks_field_info.json"))
        end
      end
    end

    def self.alter_field(id, account, val)
      return if @mapping_track_field_number == nil
      return if @mapping_track_field_number[account] == nil # no need to update absent account
      field = RagentApi::TrackFieldMapping.get_by_id(id, account, true)
      @mapping_track_field_number[account].delete(field)
      if val != nil
        @mapping_track_field_number[account] << val
      end
    end

    def self.fetch_map(account)

      @mapping_track_field_number ||= begin
        # set default map
        {'default' =>  self.fetch_default_map}
      end

      if !(@mapping_track_field_number.has_key?(account))
        CC.logger.info("fetch_map #{account}")
        ret = CC::RagentHttpApiV3.request_http_cloud_api(account, '/fields.json')
        if ret != nil
          CC.logger.info("fetch_map success for account #{account} = #{ret}")
          @mapping_track_field_number[account] = ret
        else
          raise "Account '#{account}' not available."
        end
      end
      @mapping_track_field_number[account]
    end

    # fields look like :
    # {
    #     "name": "GPRMC_VALID",
    #     "field": 3,
    #     "field_type": "string",
    #     "size": 1,
    #     "ack": 1
    # }

    # return a field struct
    def self.get_by_id(int_id, account, no_error = false)
      if RAGENT.running_env_name == 'sdk-vm'
        account = 'default'
      end
      self.fetch_map(account).each do |field|
        if "#{field['field']}" == "#{int_id}"
          return field.clone
        end
      end
      if !no_error
        raise "Field '#{int_id}' not found on account '#{account}'."
      end
    end

    def self.get_by_name(str_name, account, no_error = false)
      if RAGENT.running_env_name == 'sdk-vm'
        account = 'default'
      end
      fetch_map(account).each do |field|
        if "#{field['name']}" == "#{str_name}"
          return field.clone
        end
      end
      if !no_error
        raise "Field '#{str_name}' not found on account '#{account}'."
      end
    end

  end
end
