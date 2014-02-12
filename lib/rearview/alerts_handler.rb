
module Rearview
  class AlertsHandler
    include Rearview::Logger
    attr_reader :job,:monitor_result
    def initialize(job,monitor_results)
      @job = job
      @monitor_results = monitor_results
    end
    def run
      if Rearview.config.alerts_enabled?
        Rearview.alert_clients.each do |client|
          begin
            alert_agent = client.new
            alert_agent.alert(@job,@monitor_results)
          rescue
            logger.error "#{self} #{client} failed: #{$!}\n#{$@.join("\n")}"
          end
        end
      end
      self
    end
  end
end

