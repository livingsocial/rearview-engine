module Rearview
  class StatsService
    class StatsServiceError < StandardError; end;
    include Celluloid
    include Rearview::Logger
    def statsd
      @statsd ||= Rearview::Statsd.new
      if block_given? && Rearview.config.stats_enabled?
        yield @statsd
      end
      @statsd
    end
    def started?
      @started
    end
    def startup
      logger.info "#{self} starting up service..."
      raise StatsServiceError.new("service already started") if started?
      @started = true
      @task = Rearview::StatsTask.supervise
    end
    def shutdown
      logger.info "#{self} shutting down service..."
      raise StatsServiceError.new("service not started") unless started?
      @task.actors.first.terminate
    end
  end
end
