#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################

require 'rubygems'
require 'rufus/scheduler'
require 'json'

module Rufus


  def self.run

    RAGENT.api.mdi.tools.log.info("Rufus run start")
    CC.logger.info("in rufus run")

    scheduler = Rufus::Scheduler.new

    crons = RAGENT.cron_tasks_to_map

    crons.each do |k, v|
      p "Rufus init agent #{k}"
      RAGENT.api.mdi.tools.log.info("Rufus init agent #{k}")

      v.each do |cron_s|
        cron = JSON.parse(cron_s)
        RAGENT.api.mdi.tools.log.info("Rufus Init #{cron.class} #{cron} #{cron['cron_schedule']} #{cron['order'].class} #{cron['order']}")
        puts "Init #{cron.class} #{cron} #{cron['cron_schedule']}"
        puts "#{cron['order'].class} #{cron['order']}"
        scheduler.cron cron['cron_schedule'] do
          RAGENT.api.mdi.tools.log.info("Rufus calling order #{cron['order']}")
          RIM.handle_order(JSON.parse(cron['order']))
        end
      end

    end


    return 'started'

    # now wait and work
    #scheduler.join
  end

end
