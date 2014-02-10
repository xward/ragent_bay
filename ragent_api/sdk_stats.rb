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
    @get_time_spectrum_index_arr ||= SDK_STATS.stats['response_time']['process_time_spectrum_info']
    (0..((arr.size) -1)).each do |idx|
      return idx if time < arr[idx]
    end
    return arr.size
  end


  def self.repport_new_response_time(name, t)
    @response_tim_current_hour ||= Time.now.hour


    # migrate last hour to history
    if @response_tim_current_hour != Time.now.hour
      SDK_STATS.stats['response_time']['last_day_stats'][name] ||= begin # create if not exist
        {
          'spectrum' => [0] * SDK_STATS.stats['response_time']['process_time_spectrum_info'].size,
          'value' => [{
            'val' => 0.0,
            'stack' => 0
            }] * 60
        }
      end
      # pack spectrum
      base = SDK_STATS.stats['response_time']['last_day_stats'][name]['spectrum']
      base = base.zip(SDK_STATS.stats['response_time']['last_hour_stats'][name]['spectrum']).map{ |x,y| x + y }
      SDK_STATS.stats['response_time']['last_day_stats'][name]['spectrum'] = base
      # pack values
      base = SDK_STATS.stats['response_time']['last_day_stats'][name]['value']
      to_merge = SDK_STATS.stats['response_time']['last_hour_stats'][name]['value']

      to_merge.each_with_index do |val, idx|
        base[idx]['val'] += val['val']
        base[idx]['stack'] += val['stack']
      end
      SDK_STATS.stats['response_time']['last_day_stats'][name]['value'] = base

    end

    SDK_STATS.stats['response_time']['last_hour_stats'][name] ||= begin # create if not exist
      {
        'spectrum' => [0] * SDK_STATS.stats['response_time']['process_time_spectrum_info'].size,
        'value' => [{
          'val' => 0.0,
          'stack' => 0
          }] * 60
      }
    end

    SDK_STATS.stats['response_time']['last_hour_stats'][name]['spectrum'][get_time_spectrum_index(t)] += 1
    SDK_STATS.stats['response_time']['last_hour_stats'][name]['value'][Time.now.min]['val'] += t
    SDK_STATS.stats['response_time']['last_hour_stats'][name]['value'][Time.now.min]['stack'] += 1
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
    @daemon_stat ||= begin
      reset_stats
      @daemon_stat
    end
  end


#todo: add all + helpers
end
