module Rearview
  class Statsd < ::Statsd

    def initialize
      super(Rearview.config.statsd_connection[:host],Rearview.config.statsd_connection[:port])
      self.namespace = Rearview.config.statsd_connection[:namespace]
    end

    def self.statsd
      @@statsd ||= Rearview::Statsd.new
    end

    def self.report
      if block_given? && Rearview.config.stats_enabled?
        yield self.statsd
      end
    end

  end
end

