#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################

class AgentNotFound < StandardError
end

class UserAgentClass


  def initialize(agent_name)
    @agent_name = agent_name

    # include all user code
    require_relative "#{root_path}/initial"
    self.singleton_class.send(:include, Object.const_get("Initial_agent_#{agent_name}"))
  end

  def agent_name
    @agent_name
  end

  def root_path
    @root_path ||= begin
      File.expand_path("#{RAGENT.agents_project_src_path}/#{agent_name}")
    end
  end

  def is_agent_has_protogen
    @is_agent_has_protogen ||= File.exist?("#{RAGENT.agents_generated_src_path}/protogen_#{agent_name}/protogen_apis.rb")
  end

  def user_api
    if get_current_user_api == nil
      @user_api_env ||= begin
        env = {
          'root' => 'yes',
          'owner' => 'ragent',
          'agent_name' => 'ragent'
        }
        USER_API_FACTORY.gen_user_api(self, env)
      end
    else
      get_current_user_api
    end
  end

  # =========


  def managed_message_channels
    @managed_message_channels ||= begin
      channels = self.internal_config['dynamic_channel_str']
      CC.logger.info(channels)
      if channels.is_a? String
        channels = [channels]
      end
      if (channels == nil) || (channels.length == 0)
        raise "No channel defined for agent '#{agent_name}'"
      end
      channels
    end
  end


  def internal_config
    @internal_config ||= begin
      config = self.file_config
      tmp_config = {}
      config.each do |k, v|
        if RAGENT.what_is_internal_config.include? "#{k}"
          tmp_config[k] = v
        end
      end
      tmp_config
    end
  end

  def user_config
    @user_config ||= begin
      config = self.file_config
      tmp_config = {}
      config.each do |k, v|
        if !(RAGENT.what_is_internal_config.include? "#{k}")
          tmp_config[k] = v
        end
      end
      tmp_config
    end
  end

  def file_config
    @file_config ||= begin
      config_file_path = "#{root_path}/config/#{agent_name}.yml"
      if File.exist?(config_file_path)
        if RAGENT.running_env_name == 'ragent'
          ret = YAML::load(File.open(config_file_path))['production']
        else
          ret = YAML::load(File.open(config_file_path))['development']
        end
      else
        user_api.mdi.tools.log.error("NO CONFIG FILE FOUND in #{root_path}/config")
        user_api.mdi.tools.log.info("IE  #{config_file_path}")
        raise "No config file found for agent '#{agent_name}'"
      end
      if ret == nil
        raise "No configuration defined in this environement for agent '#{agent_name}'"
      end
      user_api.mdi.tools.log.debug("agent config : #{ret}")
      ret
    rescue Exception => e
      user_api.mdi.tools.log.error("ERROR while loading configuration")
      user_api.mdi.tools.print_ruby_exception(e)
      nil
    end
  end


  # =========

  def handle_presence(presence)

    delta_t = 0.0
    start_t = Time.now
    PUNK.start('presenceAgent')
    begin
      SDK_STATS.stats['agents'][agent_name]['received'][0] += 1
      SDK_STATS.stats['agents'][agent_name]['total_received'] += 1
      new_presence_from_device(presence)
      delta_t = Time.now - start_t
      RUBY_AGENT_STATS.report_a_last_activity("presence_#{agent_name}", "asset: #{presence.asset}")
      PUNK.end('presenceAgent','ok','process',"AGENT:#{agent_name}TNEGA callback PRESENCE '#{presence.type}' in #{(delta_t * 1000).round}ms")
    rescue Exception => e
      delta_t = Time.now - start_t
      RAGENT.api.mdi.tools.print_ruby_exception(e)
      RAGENT.api.mdi.tools.log.info("Agent '#{agent_name}' error presence :\n#{presence.inspect}")
      SDK_STATS.stats['agents'][agent_name]['err_while_process'][0] += 1
      SDK_STATS.stats['agents'][agent_name]['total_error'] += 1
      RUBY_AGENT_STATS.report_an_error("presence_#{agent_name}", "#{e}")
      PUNK.end('presenceAgent','ko','process',"AGENT:#{agent_name}TNEGA callback PRESENCE fail in #{(delta_t * 1000).round}ms")
    end

    if delta_t > 3.0
      PUNK.start('presenceAgent')
      PUNK.end('presenceAgent','ko','process',"AGENT:#{agent_name}TNEGA callback PRESENCE take too much time")
    end

    RUBY_AGENT_STATS.report_new_response_time("presence|#{agent_name}", delta_t)

  end # handle_presence


  def handle_message(msg)

    delta_t = 0
    start_t = Time.now
    begin
      # Filter channel
      return if !(managed_message_channels.include? msg.channel)

      PUNK.start('msgAgent')

      msg_type = ""
      begin
        SDK_STATS.stats['agents'][agent_name]['received'][1] += 1
        SDK_STATS.stats['agents'][agent_name]['total_received'] += 1

        if RAGENT.running_env_name == 'sdk-vm' # decode content as base64 for fake communication (vm mode)
          msg.content = Base64.decode64(msg.content)
        end

        is_protogen = false
        if is_agent_has_protogen
          begin
            # protogen decode
            msg, cookies = user_api.mdi.tools.protogen.protogen_apis.decode(msg)
            msg.content = msg
            msg.meta['protogen_cookies'] = cookies
            msg_type = "'#{msg.class}'" if "#{msg.class}" != ""

            is_protogen = true
          rescue user_api.mdi.tools.protogen.protogen_domain::Protogen::UnknownMessageType => e
            # direct run
            RAGENT.api.mdi.tools.log.warn("Server: handle_message: unknown protogen message type: #{e.inspect}")
            raise e unless $allow_protogen_fault
          rescue => e
            RAGENT.api.mdi.tools.log.warn("Server: handle_message: protogen decode error (err=#{e.inspect})")
            raise e unless $allow_protogen_fault
          end
        else # not is_agent_has_protogen
          raise "No Protogen defined" unless $allow_non_protogen
        end

        PUNK.end('msgAgent','ok','in',"AGENT:#{agent_name}TNEGA <- MSG[#{crop_ref(msg.id,4)}] #{msg_type}")

      rescue Exception => e

        RAGENT.api.mdi.tools.print_ruby_exception(e)
        RAGENT.api.mdi.tools.log.info("Agent '#{agent_name}' error message :\n#{msg.inspect}")
        SDK_STATS.stats['server']['internal_error'] += 1
        SDK_STATS.stats['agents'][agent_name]['total_error'] += 1
        RUBY_AGENT_STATS.report_an_error("message_internal_#{agent_name}", "#{e}")
        PUNK.end('msgAgent','ko','in',"AGENT:#{agent_name}TNEGA <- MSG[#{crop_ref(msg.id,4)}] #{msg_type}")
        return
      end


      # process
      PUNK.start('handle', 'handling message ...')
      if is_protogen
        RAGENT.api.mdi.tools.log.info("Server: new protogen message of imei='#{msg.asset}' to agent '#{agent_name}': #{msg.content} ---------------------")
        user_api.mdi.tools.protogen.protogen_apis.process(self, msg)
      else

        RAGENT.api.mdi.tools.log.debug("Server: new standard message  of imei='#{msg.asset}' to agent '#{agent_name}' ---------------------")
        new_msg_from_device(msg)
      end


      delta_t = Time.now - start_t
      RUBY_AGENT_STATS.report_a_last_activity("message_#{agent_name}_#{msg.channel}", "asset: #{msg.asset}")
      PUNK.end('handle','ok','process',"AGENT:#{agent_name}TNEGA callback MSG[#{crop_ref(msg.id,4)}] in #{(delta_t * 1000).round}ms")
    rescue => e
      delta_t = Time.now - start_t
      RAGENT.api.mdi.tools.log.error('Server: /msg error on agent #{agent_name} while handle_msg')
      RAGENT.api.mdi.tools.print_ruby_exception(e)
      RAGENT.api.mdi.tools.log.info("Agent '#{agent_name}' error message :\n#{msg.inspect}")
      SDK_STATS.stats['agents'][agent_name]['err_while_process'][1] += 1
      SDK_STATS.stats['agents'][agent_name]['total_error'] += 1
      RUBY_AGENT_STATS.report_an_error("message_#{agent_name}", "#{e}")
      PUNK.end('handle','ko','process',"AGENT:#{agent_name}TNEGA callback MSG[#{crop_ref(msg.id,4)}] fail in #{(delta_t * 1000).round}ms")
    end


    if delta_t > 3.0
      PUNK.start('handle')
      PUNK.end('handle','ko','process',"AGENT:#{agent_name}TNEGA callback MSG take too much time")
    end

    RUBY_AGENT_STATS.report_new_response_time("message|#{agent_name}", delta_t)

  end # handle_message



  def handle_track(track)

    delta_t = 0
    start_t = Time.now
    PUNK.start('trackAgent')
    begin
      SDK_STATS.stats['agents'][agent_name]['received'][2] += 1
      SDK_STATS.stats['agents'][agent_name]['total_received'] += 1
      new_track_from_device(track)
      delta_t = Time.now - start_t
      RUBY_AGENT_STATS.report_a_last_activity("track_#{agent_name}", "asset: #{track.asset}")
      PUNK.end('trackAgent','ok','process',"AGENT:#{agent_name}TNEGA callback TRACK with #{track.fields_data.length} new fields in #{(delta_t * 1000).round}ms")
    rescue Exception => e
      delta_t = Time.now - start_t
      RAGENT.api.mdi.tools.print_ruby_exception(e)
      RAGENT.api.mdi.tools.log.info("Agent '#{agent_name}' error track :\n#{track.inspect}")
      SDK_STATS.stats['agents'][agent_name]['err_while_process'][2] += 1
      SDK_STATS.stats['agents'][agent_name]['total_error'] += 1
      RUBY_AGENT_STATS.report_an_error("track_#{agent_name}", "#{e}")
      PUNK.end('trackAgent','ko','process',"AGENT:#{agent_name}TNEGA callback TRACK fail in #{(delta_t * 1000).round}ms")
    end


    if delta_t > 3.0
      PUNK.start('trackAgent')
      PUNK.end('trackAgent','ko','process',"AGENT:#{agent_name}TNEGA callback TRACK take too much time")
    end

    RUBY_AGENT_STATS.report_new_response_time("track|#{agent_name}", delta_t)

  end # handle_track



  def handle_order(order)
    delta_t = 0
    start_t = Time.now
    PUNK.start('orderAgent')
    begin
      SDK_STATS.stats['agents'][agent_name]['received'][3] += 1
      SDK_STATS.stats['agents'][agent_name]['total_received'] += 1
      new_order(order)
      delta_t = Time.now - start_t
      RUBY_AGENT_STATS.report_a_last_activity("order_#{agent_name}_#{order.code}", "order params: #{order.params}")
      PUNK.end('orderAgent','ok','process',"AGENT:#{agent_name}TNEGA callback ORDER with order '#{order.code}' in #{(delta_t * 1000).round}ms")
    rescue Exception => e
      delta_t = Time.now - start_t
      RAGENT.api.mdi.tools.print_ruby_exception(e)
      RAGENT.api.mdi.tools.log.info("Agent '#{agent_name}' error order :\n#{order.inspect}")
      SDK_STATS.stats['agents'][agent_name]['err_while_process'][3] += 1
      SDK_STATS.stats['agents'][agent_name]['total_error'] += 1
      RUBY_AGENT_STATS.report_an_error("order_#{agent_name}", "#{e}")
      PUNK.end('orderAgent','ko','process',"AGENT:#{agent_name}TNEGA callback ORDER fail in #{(delta_t * 1000).round}ms")
    end

    if delta_t > 10.0
      PUNK.start('orderAgent')
      PUNK.end('orderAgent','ko','process',"AGENT:#{agent_name}TNEGA callback TRACK take too much time")
    end

    RUBY_AGENT_STATS.report_new_response_time("order|#{agent_name}", delta_t)

  end # handle_order

end
