#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################

require 'rubygems'
require 'rufus/scheduler'
require 'json'

module Rufus


  def self.run

    p "Rufus start"

    scheduler = Rufus::Scheduler.new

    crons = RAGENT.cron_tasks_to_map

    crons.each do |k, v|
      p "Rufus init agent #{k}"

      v.each do |cron_s|
        cron = JSON.parse(cron_s)
        puts "Init #{cron.class} #{cron} #{cron['cron_schedule']}"
        puts "#{cron['order'].class} #{cron['order']}"
        scheduler.cron cron['cron_schedule'] do
          RIM.handle_order(JSON.parse(cron['order']))
        end
      end

    end



    # now wait and work
    #scheduler.join
  end

end
