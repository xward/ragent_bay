#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################

module RagentIncomingMessage


  def self.valid_params(params)
    if params['meta'] == nil or params['payload'] == nil
      begin
        raise "RagentIncomingMessage: bad incomming params structure: #{params}"
      rescue Exception => e
        PUNK.start('valid')
        RAGENT.api.mdi.tools.print_ruby_exception(e)
        RAGENT.api.mdi.tools.log.info("Ragent error parse params :\n#{params}")
        RUBY_AGENT_STATS.report_an_error("ragent params parse fail", "#{e}")
        SDK_STATS.stats['server']['internal_error'] += 1
        PUNK.end('valid','ko','in',"SERVER <- ?? : missing params fail")
        return false
      end
    end
    true
  end


  def self.handle_presence(params)

    # valid input
    if RIM.valid_params(params)
      account = params['meta']['account']
    else
      return
    end

    PUNK.start('new')
    RAGENT.api.mdi.tools.log.debug("\n\n\n\nServer: new incomming presence:\n#{params}")
    PUNK.end('new','ok','in',"SERVER <- PRESENCE : receive new presence")
    SDK_STATS.stats['server']['received'][0] += 1

    # forward to each agent
    RAGENT.user_class_presence_subscriber.get_subscribers.each do |user_agent_class|
      next if user_agent_class.internal_config['subscribe_presence'] == false

      begin
        PUNK.start('damned')
        # set associated api as current sdk_api
        env = {
          'account' => account,
          'agent_name' => user_agent_class.agent_name
        }
        apis = USER_API_FACTORY.gen_user_api(user_agent_class, env)

        # create Presence object
        presence = apis.mdi.dialog.create_new_presence(params)

        # set user api
        apis.initial_event_content = presence.clone
        set_current_user_api(apis)

        # process it, should never fail, but if its happen we will have a wrong error on parse fail but no deadlock
        user_agent_class.handle_presence(presence)

      rescue Exception => e
        RAGENT.api.mdi.tools.print_ruby_exception(e)
        RAGENT.api.mdi.tools.log.info("Ragent error parse presence :\n#{params}")
        RUBY_AGENT_STATS.report_an_error("ragent presence parse fail", "#{e}")
        SDK_STATS.stats['server']['err_parse'][0] += 1
        SDK_STATS.stats['server']['internal_error'] += 1
        PUNK.end('damned','ko','in',"SERVER <- PRESENCE : parse params fail")
      ensure
        PUNK.drop('damned')
        release_current_user_api
      end

    end # each user_agent_class

  end # handle_presence



  def self.handle_message(params)

    # valid input
    if valid_params(params)
      account = params['meta']['account']
      channel = params['payload']['channel']
    else
      return
    end

    # drop if unmanaged
    return unless RAGENT.supported_message_channels.include? channel || RAGENT.supported_message_channels.include?('ALL_CHANNELS')

    PUNK.start('new')
    RAGENT.api.mdi.tools.log.debug("\n\n\n\nServer: new incomming message:\n#{params}")
    SDK_STATS.stats['server']['received'][1] += 1

    # vm-mode jBinaryGate: ack the message
    if RAGENT.running_env_name == 'sdk-vm'
      PUNK.start('ackmsgvm')
      # create Message object
      begin
        ragent_msg = RAGENT.api.mdi.dialog.create_new_message(params)
        if ragent_msg.channel == 0
          RAGENT.api.mdi.tools.log.warn("The message is on channel 0, we drop it !")
          PUNK.drop('new')
          return
        end
      rescue Exception => e
        RAGENT.api.mdi.tools.print_ruby_exception(e)
        SDK_STATS.stats['server']['err_parse'][1] += 1
        SDK_STATS.stats['server']['internal_error'] += 1
        PUNK.end('ackmsgvm','ko','in',"SERVER -> ACK : ack to device fail: invalid message")
        return
      end

      begin
        RAGENT.api.mdi.tools.log.debug("Server: push_ack_to_device: creating new ack message")
        tmp_id_from_device = ragent_msg.id
        parent_id = CC.indigen_next_id
        ragent_msg.id = parent_id
        channel_str = ragent_msg.channel
        channel_int = RAGENT.map_supported_message_channels[channel_str]
        RAGENT.api.mdi.tools.log.debug("Server: push_ack_to_device: for channel #{channel_str} using number #{channel_int}")

        ack_map = Hash.new
        ack_map['channel'] =  channel_int
        ack_map['channelStr'] = channel_str
        ack_map['tmpId'] = tmp_id_from_device
        ack_map['msgId'] = parent_id
        msgAck = ragent_msg.clone
        msgAck.content = ack_map.to_json
        msgAck.type = 'ackmessage'

        RAGENT.api.mdi.tools.log.info("Server: push_ack_to_device: adding Ack message with tmpId=#{ack_map['tmpId']} and msgId=#{ack_map['msgId']}")

        push_something_to_device(msgAck.to_hash)

        TestsHelper.id_generated(parent_id, tmp_id_from_device)

        SDK_STATS.stats['server']['total_ack_queued'] += 1
        PUNK.end('ackmsgvm','ok','in',"SERVER -> ACK[#{parent_id}] of MSG[#{tmp_id_from_device}]")
      rescue Exception => e
        RAGENT.api.mdi.tools.log.error("Server: push_ack_to_device error with payload = \n#{ragent_msg}")
        RAGENT.api.mdi.tools.print_ruby_exception(e)
        PUNK.end('ackmsgvm','ko','in',"SERVER -> ACK : ack to device fail")
        return
      end
    else
      # create Message object
      begin
        ragent_msg = RAGENT.api.mdi.dialog.create_new_message(params)
      rescue Exception => e
        RAGENT.api.mdi.tools.print_ruby_exception(e)
        RAGENT.api.mdi.tools.log.info("Ragent error parse message :\n#{params}")
        RUBY_AGENT_STATS.report_an_error("ragent track parse fail", "#{e}")
        RAGENT.api.mdi.tools.log.info("error on message :\n#{msg.inspect}")
        SDK_STATS.stats['server']['err_parse'][1] += 1
        SDK_STATS.stats['server']['internal_error'] += 1
        return
      end
    end # end vm mode



    PUNK.end('new','ok','in',"SERVER <- MSG : receive new message")

    # forward to each agent
    RAGENT.user_class_message_subscriber.get_subscribers.each do |user_agent_class|
      next if user_agent_class.internal_config['subscribe_message'] == false

      if user_agent_class.internal_config['message_whitelist_channels'].include? channel || user_agent_class.internal_config['message_whitelist_channels'].include?('ALL_CHANNELS')

        begin
          PUNK.start('damned')
          env = {
            'account' => account,
            'agent_name' => user_agent_class.agent_name
          }

          # set associated api as current sdk_api
          apis = USER_API_FACTORY.gen_user_api(user_agent_class, env)
          apis.initial_event_content = ragent_msg.clone
          set_current_user_api(apis)

          # Say it
          RAGENT.api.mdi.tools.log.info("Server: new message (id=#{ragent_msg.id}) of asset '#{ragent_msg.asset}' on channel '#{ragent_msg.channel}' proccessing by '#{user_agent_class.agent_name}' with env '#{apis.user_environment_md5}'.")

          # process it, should never fail, but if its happen we will have a wrong error on parse fail but no deadlock
          user_agent_class.handle_message(ragent_msg)

        rescue Exception => e
          RAGENT.api.mdi.tools.print_ruby_exception(e)
          RAGENT.api.mdi.tools.log.info("Ragent error init api env :\n#{env}")
          RUBY_AGENT_STATS.report_an_error("ragent message init env", "#{e}")
          SDK_STATS.stats['server']['err_parse'][1] += 1
          SDK_STATS.stats['server']['internal_error'] += 1
          PUNK.end('damned','ko','in',"SERVER <- MESSAGE : bad init apis set_current_user_api")
        ensure
          PUNK.drop('damned')
          release_current_user_api
        end

      end
    end # each user_agent_class


  end # handle_message


  def self.handle_track(params)

    RAGENT.api.mdi.tools.log.debug("new track")

    # valid input
    if valid_params(params)
      account = params['meta']['account']
    else
      return
    end

    PUNK.start('new')
    RAGENT.api.mdi.tools.log.debug("\n\n\n\nServer: new incomming track:\n#{params}")
    PUNK.end('new','ok','in',"SERVER <- TRACK : receive new track")
    SDK_STATS.stats['server']['received'][2] += 1


    # forward to each agent
    RAGENT.user_class_track_subscriber.get_subscribers.each do |user_agent_class|

      next if user_agent_class.internal_config['subscribe_track'] == false

      begin
        PUNK.start('damned')
        env = {
          'account' => account,
          'agent_name' => user_agent_class.agent_name
        }

        apis = USER_API_FACTORY.gen_user_api(user_agent_class, env)

        # create Track object
        track = apis.mdi.dialog.create_new_track(params)

        # set associated api as current sdk_api
        apis.initial_event_content = track.clone
        set_current_user_api(apis)


        # process it, should never fail, but if its happen we will have a wrong error on parse fail but no deadlock
        user_agent_class.handle_track(track)

      rescue Exception => e
        RAGENT.api.mdi.tools.print_ruby_exception(e)
        RAGENT.api.mdi.tools.log.info("Ragent error parse track :\n#{params}")
        RUBY_AGENT_STATS.report_an_error("ragent track parse fail", "#{e}")
        SDK_STATS.stats['server']['err_parse'][2] += 1
        SDK_STATS.stats['server']['internal_error'] += 1
        PUNK.end('damned','ko','in',"SERVER <- TRACK : parse params fail")
      ensure
        PUNK.drop('damned')
        release_current_user_api
      end

    end # each user_agent_class


  end # handle_track


  def self.handle_order(params)

    RAGENT.api.mdi.tools.log.debug("new order")

    # filter
    assigned_agent = RAGENT.get_agent_from_name(params['agent'])

    if assigned_agent == nil
      PUNK.start('damned')
      PUNK.end('damned','ko','in',"SERVER <- ORDER : agent not found")
    end

    PUNK.start('new')
    RAGENT.api.mdi.tools.log.debug("\n\n\n\nServer: new incomming order:\n#{params}")
    SDK_STATS.stats['server']['received'][3] += 1
    PUNK.end('new','ok','in',"SERVER <- ORDER for agent '#{assigned_agent.agent_name}'")


    begin
      PUNK.start('damned')
      env = {
        'env' => 'order',
        'agent_name' => assigned_agent.agent_name
      }
      apis = USER_API_FACTORY.gen_user_api(assigned_agent, env)

      # create Order object
      order = apis.mdi.dialog.create_new_order(params)

      # set associated api as current sdk_api
      apis.initial_event_content = order.clone
      set_current_user_api(apis)


      # process it, should never fail, but if its happen we will have a wrong error on parse fail but no deadlock
      assigned_agent.handle_order(order)

    rescue AgentNotFound => e
      RAGENT.api.mdi.tools.print_ruby_exception(e)
      response.body = 'service unavailable'
      SDK_STATS.stats['server']['remote_call_unused'] += 1
      SDK_STATS.stats['server']['total_error'] += 1
      PUNK.end('damned','ko','in',"SERVER <- ORDER : agent not found")
    rescue Exception => e
      RAGENT.api.mdi.tools.print_ruby_exception(e)
      RAGENT.api.mdi.tools.log.info("Ragent error parse order :\n#{params}")
      RUBY_AGENT_STATS.report_an_error("ragent order parse fail", "#{e}")
      SDK_STATS.stats['server']['err_parse'][3] += 1
      SDK_STATS.stats['server']['internal_error'] += 1
      PUNK.end('damned','ko','in',"SERVER <- ORDER : parse params fail")
    ensure
      PUNK.drop('damned')
      release_current_user_api
    end

  end # handle_order


  # futur !
  def self.handle_collection(params)
    #RAGENT.api.mdi.tools.log.info("new collection #{params}")

    # valid input
    if valid_params(params)
      account = params['meta']['account']
    else
      return
    end

    PUNK.start('new')
    RAGENT.api.mdi.tools.log.debug("\n\n\n\nServer: new incomming collection:\n#{params}")
    PUNK.end('new','ok','in',"SERVER <- COLLECTION : receive new collection")
    SDK_STATS.stats['server']['received'][4] += 1


    # forward to each agent
    RAGENT.user_class_collection_subscriber.get_subscribers.each do |user_agent_class|

      next if user_agent_class.internal_config['subscribe_collection'] == false

      begin
        PUNK.start('damned')
        env = {
          'account' => account,
          'agent_name' => user_agent_class.agent_name
        }

        apis = USER_API_FACTORY.gen_user_api(user_agent_class, env)

        # create collecion object
        collection = apis.mdi.dialog.create_new_collection(params)

        # set associated api as current sdk_api
        apis.initial_event_content = collection.clone
        set_current_user_api(apis)

        # process it, should never fail, but if its happen we will have a wrong error on parse fail but no deadlock
        user_agent_class.handle_collection(collection)
      rescue Exception => e
        RAGENT.api.mdi.tools.print_ruby_exception(e)
        RAGENT.api.mdi.tools.log.info("Ragent error parse collection :\n#{params}")
        RUBY_AGENT_STATS.report_an_error("ragent collection parse fail", "#{e}")
        SDK_STATS.stats['server']['err_parse'][4] += 1
        SDK_STATS.stats['server']['internal_error'] += 1
        PUNK.end('damned','ko','in',"SERVER <- COLLECTION : parse params fail")
      ensure
        PUNK.drop('damned')
        release_current_user_api
      end

    end # each user_agent_class

  end # handle_collection

  # Message handler for an agent which has subscribed to an arbitrary queue
  def self.handle_other_queue(params, queue_name)

    PUNK.start('new')
    RAGENT.api.mdi.tools.log.debug("\n\n\n\nServer: new incoming message on queue '#{queue_name}':\n#{params}")
    PUNK.end('new','ok','in',"SERVER <- MESSAGE : receive from queue #{queue_name}")

    # TODO: add stats

    # forward to agents
    RAGENT.user_class_other_subscribers(queue_name).get_subscribers.each do |user_agent_class|
      begin
        PUNK.start("damned")
        env = {
          'account' => 'other_queue',
          'agent_name' => user_agent_class.agent_name
        }
        apis = USER_API_FACTORY.gen_user_api(user_agent_class, env)
        set_current_user_api(apis)
        user_agent_class.handle_other_queue(params, queue_name)
      ensure
        PUNK.drop("damned")
        release_current_user_api
      end

    end

  end


  # futur !
  def self.handle_alert(params)

    RAGENT.api.mdi.tools.log.info("new alert")

  end # handle_alert

end

RIM = RagentIncomingMessage
