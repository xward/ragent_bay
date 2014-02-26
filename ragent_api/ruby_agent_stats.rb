#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2014
#########################################################

require 'json'

module RUBY_AGENT_STATS


  def self.init(agent_name, type, run_id, version, static_infos)
    @stats_mutex ||= Mutex.new
    RUBY_AGENT_STATS.reset_stats
    @ruby_agent_stats['name'] = agent_name
    @ruby_agent_stats['type'] = type
    @ruby_agent_stats['start_time'] = Time.now.to_i
    @ruby_agent_stats['start_time_date'] = Time.now
    @ruby_agent_stats['run_id'] = run_id
    @ruby_agent_stats['version'] = version
    @ruby_agent_stats['static_infos'] = static_infos
  end

  def self.flush_to_file(additional_specific_infos)
    @stats_mutex.synchronize do
      RUBY_AGENT_STATS.check_response_time_rotation

      @ruby_agent_stats['uptime'] = (Time.now - @ruby_agent_stats['start_time_date']).to_i
      @ruby_agent_stats['dynamic_infos'] = additional_specific_infos

      name = @ruby_agent_stats['name']
      id = @ruby_agent_stats['run_id']
      File.open("/tmp/#{name}_info_#{name}_#{id}", 'w') { |file| file.write(@ruby_agent_stats.to_json) }
    end
  end

  def self.reset_stats
    @stats_mutex.synchronize do
      @ruby_agent_stats = {
        'response_time' => {
          'process_time_spectrum_info' => [0.01, 0.1, 1, 5, 30, 60, 180, 600, 1800],
          'last_hour_stats' => {},
          'last_day_stats' => {}
         },
        'last_activity' => {},
        'errors' => {},
        'rq_pull_speed' => [],
        'rq_process_speed' => []
        }
      end
  end

  #  | 10 ms | 100 ms | 1sec | 5sec | 30sec | 1 min | 3 min | 10 min | 30 min |
  def self.get_time_spectrum_index(time)
    @get_time_spectrum_index_arr ||= @ruby_agent_stats['response_time']['process_time_spectrum_info']
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

  def self.create_new_last_hour_stat
    {
      'ref_time' => (Time.now.to_i / 3600).floor * 3600,
      'spectrum' => [0] * @ruby_agent_stats['response_time']['process_time_spectrum_info'].size,
      'value' => Array.new(60){ |i|
        RUBY_AGENT_STATS.base_response_time_obj
      }
    }
  end

  def self.create_new_last_hour_in_day_stat(ref_time)
    {
      'ref_time' => ref_time,
      'spectrum' => [0] * @ruby_agent_stats['response_time']['process_time_spectrum_info'].size,
      'value' => RUBY_AGENT_STATS.base_response_time_obj
    }
  end


  def self.check_response_time_rotation(name = "ALL")

    if name == 'ALL'
      @ruby_agent_stats['response_time']['last_hour_stats'].each do |k,v|
        RUBY_AGENT_STATS.check_response_time_rotation(k) if k != 'ALL'
      end
      return
    end

    begin

      my_hour = Time.now.hour

      # Create stats of last hour if not exists
      @ruby_agent_stats['response_time']['last_hour_stats'][name] ||= begin
        RUBY_AGENT_STATS.create_new_last_hour_stat
      end

      # Create stats of last day if not exists
      @ruby_agent_stats['response_time']['last_day_stats'][name] ||= []

      # migrate last hour to history
      cur_time = @ruby_agent_stats['response_time']['last_hour_stats'][name]['ref_time']
      if Time.at(cur_time).hour != my_hour
        ref_hour_for_day = RUBY_AGENT_STATS.create_new_last_hour_in_day_stat(@ruby_agent_stats['response_time']['last_hour_stats'][name]['ref_time'])

        # pack spectrum
        ref_hour_for_day['spectrum'] = @ruby_agent_stats['response_time']['last_hour_stats'][name]['spectrum'].clone

        # pack value
        base = RUBY_AGENT_STATS.base_response_time_obj
        min_val = nil
        max_val = nil
        @ruby_agent_stats['response_time']['last_hour_stats'][name]['value'].each do |value|
          base['val'] += value['val']
          base['stack'] += value['stack']

          cur_min = value['min']
          if cur_min != nil
            if min_val == nil
              min_val = cur_min
            else
              if cur_min < min_val
                min_val = cur_min
              end
            end
          end
          cur_max = value['max']
          if cur_max != nil
            if max_val == nil
              max_val = cur_max
            else
              if cur_max < max_val
                max_val = cur_max
              end
            end
          end
        end
        base['min'] = min_val
        base['max'] = max_val
        ref_hour_for_day['value'] = base

        @ruby_agent_stats['response_time']['last_day_stats'][name] << ref_hour_for_day
        if @ruby_agent_stats['response_time']['last_day_stats'][name].size > 24
          @ruby_agent_stats['response_time']['last_day_stats'][name].shift #doen't work ?
        end

        @ruby_agent_stats['response_time']['last_hour_stats'][name] = RUBY_AGENT_STATS.create_new_last_hour_stat
      end

    rescue Exception => e
      RUBY_AGENT_STATS.report_an_error('check_response_time_rotation', e.inspect)
    end

  end

  # t in sec
  def self.report_new_response_time(name, t)
    @stats_mutex.synchronize do
      # begin

        RUBY_AGENT_STATS.check_response_time_rotation(name)

        my_min = Time.now.min

        #proccess add
        @ruby_agent_stats['response_time']['last_hour_stats'][name]['spectrum'][get_time_spectrum_index(t)] += 1
        @ruby_agent_stats['response_time']['last_hour_stats'][name]['value'][my_min]['val'] += t
        @ruby_agent_stats['response_time']['last_hour_stats'][name]['value'][my_min]['stack'] += 1

        # check min max
        cur_min = @ruby_agent_stats['response_time']['last_hour_stats'][name]['value'][my_min]['min']
        cur_max = @ruby_agent_stats['response_time']['last_hour_stats'][name]['value'][my_min]['max']

        cur_min = t if cur_min == nil
        cur_max = t if cur_max == nil
        cur_min = t if cur_min > t
        cur_max = t if cur_max < t

        @ruby_agent_stats['response_time']['last_hour_stats'][name]['value'][my_min]['min'] = cur_min
        @ruby_agent_stats['response_time']['last_hour_stats'][name]['value'][my_min]['max'] = cur_max

      # rescue Exception => e
      #   RUBY_AGENT_STATS.report_an_error('report_new_response_time', e.inspect)
      # end
    end
  end

  def self.report_a_last_activity(name, description)
    @stats_mutex.synchronize do
      @ruby_agent_stats['last_activity'][name] = {
        'desc' => description,
        'date' => "#{Time.now.to_i}"
      }
    end
  end

  def self.report_a_rq_pulling_speed(speed)
    @stats_mutex.synchronize do
      @ruby_agent_stats['rq_pull_speed'] << speed
      if @ruby_agent_stats['rq_pull_speed'].size > 2880
        @ruby_agent_stats['rq_pull_speed'].shift
      end
    end
  end

  def self.report_a_rq_process_speed(speed)
    @stats_mutex.synchronize do
      @ruby_agent_stats['rq_process_speed'] << speed
      if @ruby_agent_stats['rq_process_speed'].size > 2880
        @ruby_agent_stats['rq_process_speed'].shift
      end
    end
  end

  def self.report_a_rq_process_count(count)
    @stats_mutex.synchronize do
      @ruby_agent_stats['rqueue_msg_pulled_count'] = count
    end
  end

  def self.report_an_error(name, value)
    @stats_mutex.synchronize do
      err = @ruby_agent_stats['errors'][name]
      if err == nil
        @ruby_agent_stats['errors'][name] = {
          'count' => 1,
          'values' => [value],
          'date' => "#{Time.now}"
        }
      else
        @ruby_agent_stats['errors'][name]['count'] += 1
        @ruby_agent_stats['errors'][name]['values'] << value
        if @ruby_agent_stats['errors'][name]['values'].size > 100
          @ruby_agent_stats['errors']['values'].shift
        end
        @ruby_agent_stats['errors'][name]['date'] = "#{Time.now.to_i}"
      end
    end
  end


  def self.stats
    @stats_mutex.synchronize do
      reset_stats if @ruby_agent_stats == nil
    end
    @ruby_agent_stats
  end

end
