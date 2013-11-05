require 'optparse'

module Rearview
  class Configuration < Struct.new(:default_from, :graphite_url, :pagerduty_url, :sandbox_exec,
      :sandbox_timeout, :sandbox_dir, :enable_alerts, :preload_jobs, :logger, :enable_monitor, :verify)

    DEFAULTS = {
      default_from: "rearview@livingsocial.com",
      graphite_url: "http://graphite.iad.livingsocial.net",
      pagerduty_url: "https://events.pagerduty.com/generic/2010-04-15/create_event.json",
      sandbox_timeout: 5,
      enable_alerts: true,
      preload_jobs: true,
      verify: false,
      enable_monitor: true
    }

    def initialize
      super
      set_defaults
    end

    def alerts_enabled?
      enable_alerts
    end

    def monitor_enabled?
      enable_monitor
    end

    def preload_jobs?
      preload_jobs
    end

    def verify?
      verify
    end

    def with_argv(argv)
      OptionParser.new do |opts|
        opts.on("--[no-]preload", "Enable/disable job loading")  { |v| self.preload_jobs = v }
        opts.on("--[no-]alerts", "Enable/disable alerts")  { |v| self.enable_alerts = v }
        opts.on("--[no-]monitor", "Enable/disable monitor")  { |v| self.enable_monitor = v }
        opts.on("--[no-]verify", "Enable/disable verification")  { |v| self.verify = v }
      end.parse!(argv)
    end

    def set_defaults
      members.each { |member| send("#{member}=", DEFAULTS[member.to_sym]) }
    end

    def to_s
      @elems = []
      members.each { |m| @elems << "Rearview::Configuration #{m} : #{self[m]}" }
      @elems.join("\n")
    end

  end
end
