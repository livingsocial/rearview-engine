module Rearview
  class StatsService
    class StatsServiceError < StandardError; end;
    include Celluloid
    include Rearview::Logger
    def statsd
      @statsd ||= Rearview::Statsd.new
    end
    def started?
      @started
    end
    def startup
      raise StatsServiceError.new("service already started") if started?
      @started = true
      @stats_task = Rearview::StatsTask.supervise
    end
    def shutdown
      raise StatsServiceError.new("service not started") unless started?
      @stats_task.actors.first.terminate
    end
  end
end
