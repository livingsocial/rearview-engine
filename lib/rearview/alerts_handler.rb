
module Rearview
  class AlertsHandler
    include Rearview::Logger
    attr_reader :job,:monitor_result
    def initialize(job,monitor_results)
      @job = job
      @monitor_results = monitor_results
    end
    def run
      logger.info "#{self} run"
      if Rearview.config.alerts_enabled?
        Rearview.alert_clients.each do |client|
          alert_agent = client.new
          begin
            alert_agent.alert(@job,@monitor_results)
          rescue
            logger.error "#{self} #{alert_agent} failed: #{$!}\n#{$@.join("\n")}"
          end
        end
      end
      self
    rescue
      logger.error "#{self} failed: #{$!}\n#{$@.join("\n")}"
      self
    end

    def to_s
      "#{super.to_s} [jobId:#{@job.id} threadId:#{java.lang.Thread.currentThread.getId} threadName:#{java.lang.Thread.currentThread.getName}]"
    end

  end
end

