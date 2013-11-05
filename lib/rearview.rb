require "rearview/engine"
require "rearview/concerns"
require "rearview/ext/state_machine"
require "rearview/constants_module_maker"
require 'rearview/logger'
require 'rearview/cron_helper'
require 'rearview/graphite_parser'
require 'rearview/results_handler'
require 'rearview/alerts_handler'
require 'rearview/uri_helper'
require 'rearview/alerts'
require 'rearview/monitor_runner'
require 'rearview/monitor_task'
require 'rearview/distribute'
require 'rearview/monitor_supervisor'
require 'rearview/monitor_service'
require 'rearview/configuration'
require 'rearview/sandbox'
require 'rearview/version'

module Rearview
  include Rearview::Logger

  class << self
    attr_accessor :monitor_service,:alert_clients
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
    @logger = config.logger if(config.logger.present?)
    logger.info "[#{self}] booting..."
    logger.info "[#{self}] using configuration: \n#{config}"
    if config.verify?
      logger.info "[#{self}] verifying sandbox..."
      if Rearview::Sandbox.valid?
        logger.info "[#{self}] sandbox verified"
      else
        logger.error "[#{self}] sandbox verification FAILED"
      end
    end
    Celluloid.logger = @logger
    jobs = ( config.preload_jobs? ? Job.schedulable : [] )
    logger.info "[#{self}] starting up monitor service for (#{jobs.count}) job(s)"
    @monitor_service = Rearview::MonitorService.new(jobs)
    if config.monitor_enabled?
      @monitor_service.startup
    else
      logger.warn "[#{self}] monitor disabled"
    end
    @alert_clients = Rearview::Alerts.registry.values
    @booted = true
  end

end
