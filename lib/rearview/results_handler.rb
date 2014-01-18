
module Rearview
  class ResultsHandler
    attr_reader :status,:job,:monitor_results
    include Rearview::Logger
    def initialize(job,monitor_results)
      @job = job
      @status = Job::Status::ERROR
      @monitor_results = monitor_results || {}
    end
    def run
      logger.info "#{self} run"
      normalized_results = Rearview::MonitorRunner.normalize_results(@monitor_results)
      @status = normalized_results[:status] || @status

      job_data = JobData.find_or_create_by(job_id: @job.id)
      job_data.data = normalized_results
      job_data.save!

      @job.last_run = Time.now.utc
      event = if Job::Status.values.include?(@status.to_s)
                @status.to_sym
              else
                :error
              end
      logger.info "#{self} firing event :#{event} for #{@job.inspect}"
      @job.fire_event(event,{:monitor_results=>@monitor_results,:job_error=>{:message=>normalized_results[:output]}})

      self
    rescue
      logger.error "#{self} process results failed: #{$!}\n#{$@.join("\n")}"
      self
    end
  end
end
