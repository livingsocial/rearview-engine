module Rearview
  class Statsd < ::Statsd

    def initialize
      super(Rearview.config.statsd_connection[:host],Rearview.config.statsd_connection[:port])
      self.namespace = Rearview.config.statsd_connection[:namespace]
    end

  end
end

