require 'json'

module Rearview
  class MonitorTask
    class MonitorTaskError < StandardError; end;
    include Celluloid
    include Celluloid::Logger
    attr_reader :job,:timer,:initial_delay
    def initialize(job,initial_delay=0,start=true)
      debug "#{self} intialize initial_delay:#{initial_delay} start:#{start}"
      @job = job
      @initial_delay = initial_delay
      schedule if start
    end
    def schedule
      debug "#{self} schedule"
      if ActiveRecord::Base.connection_pool.active_connection?
        ActiveRecord::Base.connection_pool.release_connection
      end
      # TODO is this really necessary?
      if(@timer)
        @timer.cancel
      end
      delay = @job.delay + @initial_delay
      debug "#{self} next run in #{delay}s"
      @timer = after(delay) { self.run }
    end
    def run
      debug "#{self} run"
      @initial_delay = 0
      result = Rearview::MonitorRunner.run(@job.metrics, @job.monitor_expr, @job.minutes)
      ActiveRecord::Base.connection_pool.with_connection do
        @job.last_run = Time.now.utc
        Rearview::ResultsHandler.new(@job,result).run
      end
    rescue
      error "#{self} run failed: #{$!}\n#{$@.join("\n")}"
      ActiveRecord::Base.connection_pool.with_connection do
        @job.last_run = Time.now.utc
        @job.error!
      end
    ensure
      schedule
    end
    def to_s
      "#{super.to_s} [jobId:#{self.job.try(:id)||'nil'} threadId:#{java.lang.Thread.currentThread.getId} threadName:#{java.lang.Thread.currentThread.getName}]"
    end
  end
end

