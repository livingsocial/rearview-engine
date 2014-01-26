require 'graphite'

require 'rearview/engine'
require 'rearview/concerns'
require 'rearview/ext/state_machine'
require 'rearview/ext/numeric'
require 'rearview/constants_module_maker'
require 'rearview/logger'
require 'rearview/log_formatter'
require 'rearview/cron_helper'
require 'rearview/results_handler'
require 'rearview/alerts_handler'
require 'rearview/url_helper'
require 'rearview/alerts'
require 'rearview/monitor_runner'
require 'rearview/monitor_task'
require 'rearview/distribute'
require 'rearview/monitor_supervisor'
require 'rearview/monitor_service'
require 'rearview/configuration'
require 'rearview/vm'
require 'rearview/statsd'
require 'rearview/stats_task'
require 'rearview/stats_service'
require 'rearview/version'

module Rearview
  include Rearview::Logger

  class << self
    attr_accessor :monitor_service,:stats_service,:alert_clients
  end

  module_function

  def logger
    @logger ||= Rails.logger
  end

  def logger=(logger)
    @logger = logger
  end

  def booted?
    @booted
  end

  def configure
    yield config
  end

  def config
    @config ||= Rearview::Configuration.new
  end

  def boot!
    Celluloid.logger = @logger = config.logger if(config.logger.present?)
    logger.info "booting..."
    logger.info "using configuration: \n#{config.dump}"
    if config.verify?
      unless config.valid?
        logger.warn "configuration check FAILED: \n#{config.errors.full_messages.join("\n")}"
      end
    end
    jobs = ( config.preload_jobs? ? Job.schedulable : [] )
    logger.info "starting up monitor service for (#{jobs.count}) job(s)"
    @monitor_service = Rearview::MonitorService.new(jobs)
    if config.monitor_enabled?
      @monitor_service.startup
    else
      logger.warn "monitor disabled!"
    end
    if config.stats_enabled?
      logger.info "starting up stats service"
      @stats_service = Rearview::StatsService.supervise
      @stats_service.actors.first.startup
    end
    @alert_clients = Rearview::Alerts.registry.values
    @booted = true
  end

end
