#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################

module SDK_STATS


  def self.reset_stats
    @daemon_stat = {
      'response_time' => {
        'process_time_spectrum_info' => [0.01, 0.1, 1, 5, 30, 60, 180, 600, 1800],
        'last_hour_stats' => {},
        'last_day_stats' => {}
      },
      'server' => {
        'uptime' => '-1',
        'start_time' => 'never',
        'total_received' => 0,
        'total_error' => 0,
        'internal_error' => 0,
        'total_sent' => 0,
        'received' => [0] * 5,
        'pulled_from_queue' => [0] * 5,
        'ack_sent_to_device' => [0] * 5,
        'err_parse' => [0] * 5,
        'err_dyn_channel' => [0] * 5,
        'err_while_send_ack' => [0] * 5,
        'in_queue' => 0,
        'total_ack_queued' => 0,
        'total_queued' => 0,
        'remote_call_unused' => 0
        },
        'agents' => {}
      }
    RAGENT.user_class_subscriber.get_subscribers.each do |user_agent_class|
      agent_name = user_agent_class.agent_name
      @daemon_stat['agents'][agent_name] = {
        'total_received' => 0,
        'total_error' => 0,
        'total_sent' => 0,
        'received' => [0] * 5,
        'err_while_process' => [0] * 5,
        'reply_sent_to_device' => 0,
        'err_on_reply' => 0,
        'push_sent_to_device' => 0,
        'err_on_push' => 0,
        'inject_to_cloud' => 0,
        'err_on_inject' => 0,
        'upstream_data' => [0] * 5,
        'downstream_data' => [0] * 5
      }
    end
  end

  #  | 10 ms | 100 ms | 1sec | 5sec | 30sec | 1 min | 3 min | 10 min | 30 min |
  def self.get_time_spectrum_index(time)
    @get_time_spectrum_index_arr ||= @daemon_stat['response_time']['process_time_spectrum_info']
    (0..((@get_time_spectrum_index_arr.size) -1)).each do |idx|
      return idx if time < @get_time_spectrum_index_arr[idx]
    end
    return @get_time_spectrum_index_arr.size
  end

  def self.base_response_time_obj
    {
      'val' => 0.0,
      'min' => nil,
      'max' => nil,
      'stack' => 0
    }
  end

  def self.create_new_last_hour_stat(ref_hour)
    {
      'ref_hour' => ref_hour,
      'spectrum' => [0] * @daemon_stat['response_time']['process_time_spectrum_info'].size,
      'value' => Array.new(60){ |i|
        SDK_STATS.base_response_time_obj
      }
    }
  end

  def self.create_new_last_hour_in_day_stat(ref_hour)
    {
      'ref_hour' => ref_hour,
      'spectrum' => [0] * @daemon_stat['response_time']['process_time_spectrum_info'].size,
      'value' => SDK_STATS.base_response_time_obj
    }
  end


  def self.repport_new_response_time(name, t)
    ref_hour = Time.now.hour

    # Create stats of last hour if not exists
    @daemon_stat['response_time']['last_hour_stats'][name] ||= begin
      SDK_STATS.create_new_last_hour_stat(ref_hour)
    end

    # Create stats of last day if not exists
    @daemon_stat['response_time']['last_day_stats'][name] ||= []



    # migrate last hour to history
    if @daemon_stat['response_time']['last_hour_stats'][name]['ref_hour'] != ref_hour
      ref_hour_for_day = SDK_STATS.create_new_last_hour_in_day_stat(@daemon_stat['response_time']['last_hour_stats'][name]['ref_hour'])

      # pack spectrum
      ref_hour_for_day['spectrum'] = @daemon_stat['response_time']['last_hour_stats'][name]['spectrum'].clone


      # pack value
      base = SDK_STATS.base_response_time_obj
      min_val = nil
      max_val = nil
      @daemon_stat['response_time']['last_hour_stats'][name]['value'].each do |value|
        base['val'] += value['val']
        base['stack'] += value['stack']

        cur_min = value['min']
        if min_val == nil
          min_val = cur_min
        else
          if cur_min < min_val
            min_val = cur_min
          end
        end
        cur_max = value['max']
        if max_val == nil
          max_val = cur_max
        else
          if cur_max < max_val
            max_val = cur_max
          end
        end
      end
      base['min'] = min_val
      base['max'] = max_val
      ref_hour_for_day['value'] = base

      @daemon_stat['response_time']['last_day_stats'][name] << ref_hour_for_day
      if @daemon_stat['response_time']['last_day_stats'][name].size > 23
        @daemon_stat['response_time']['last_day_stats'][name].shift
      end

      @daemon_stat['response_time']['last_hour_stats'][name] = SDK_STATS.create_new_last_hour_stat(ref_hour)
    end

    #proccess add
    @daemon_stat['response_time']['last_hour_stats'][name]['spectrum'][get_time_spectrum_index(t)] += 1
    @daemon_stat['response_time']['last_hour_stats'][name]['value'][Time.now.min]['val'] += t
    @daemon_stat['response_time']['last_hour_stats'][name]['value'][Time.now.min]['stack'] += 1


    if @daemon_stat['response_time']['last_hour_stats'][name]['value'][Time.now.min]['max'] == nil
      @daemon_stat['response_time']['last_hour_stats'][name]['value'][Time.now.min]['max'] = t
    end

    if @daemon_stat['response_time']['last_hour_stats'][name]['value'][Time.now.min]['min'] == nil
      @daemon_stat['response_time']['last_hour_stats'][name]['value'][Time.now.min]['min'] = t
    end


    if t > @daemon_stat['response_time']['last_hour_stats'][name]['value'][Time.now.min]['max']
      @daemon_stat['response_time']['last_hour_stats'][name]['value'][Time.now.min]['max'] = t
    end

    if t < @daemon_stat['response_time']['last_hour_stats'][name]['value'][Time.now.min]['min']
      @daemon_stat['response_time']['last_hour_stats'][name]['value'][Time.now.min]['min'] = t
    end

  end


  # stat per type of protogen message

  def self.count_agents_internal_error
    count = 0
    RAGENT.user_class_subscriber.get_subscribers.each do |user_agent_class|
      @daemon_stat['agents'][user_agent_class.agent_name]['err_while_process'].each do |err|
        count += err
      end
    end
    count
  end

  def self.count_agents_received
    result = [0] * 5
    RAGENT.user_class_subscriber.get_subscribers.each do |user_agent_class|
      result =  result.zip(@daemon_stat['agents'][user_agent_class.agent_name]['received']).map{ |x,y| x + y }
    end
    result
  end

  def self.count_agents_push
    count = 0
    RAGENT.user_class_subscriber.get_subscribers.each do |user_agent_class|
      count += @daemon_stat['agents'][user_agent_class.agent_name]['push_sent_to_device']
    end
    count
  end

  def self.count_agents_reply
    count = 0
    RAGENT.user_class_subscriber.get_subscribers.each do |user_agent_class|
      count += @daemon_stat['agents'][user_agent_class.agent_name]['reply_sent_to_device']
    end
    count
  end

  def self.stats
    @stats_mutex ||= Mutex.new
    @stats_mutex.synchronize do
      reset_stats if @daemon_stat == nil
    end
    @daemon_stat
  end



#todo: add all + helpers
end
