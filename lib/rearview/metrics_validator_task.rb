require 'json'

module Rearview
  class MetricsValidatorTask
    class StatsTaskError < StandardError; end;
    include Celluloid
    include Rearview::Logger
    attr_reader :cron_expression

    def initialize(cron_expression,start=true)
      @cron_expression = cron_expression
      schedule if start
    end

    def schedule
      logger.debug "#{self} schedule"
      if ActiveRecord::Base.connection_pool.active_connection?
        ActiveRecord::Base.connection_pool.release_connection
      end
      delay = if cron_expression == '0 * * * * ?'
                60.0
              else
                Rearview::CronHelper.next_valid_time_after(cron_expression)
              end
      logger.debug "#{self} scheduled to run in #{delay}s"
      @timer = after(delay) { self.run }
    end

    def run
      logger.debug "#{self} run"
      validator = Rearview::MetricsValidator.new({ attributes: [:metrics], cache: true })
      ActiveRecord::Base.connection_pool.with_connection do
        Rearview::Job.schedulable.load.each do |job|
          validator.validate_each(job,:metrics,job.metrics)
          unless job.errors[:metrics].empty?
            alert_validation_failed(job)
          end
        end
      end
    rescue
      logger.error "#{self} run failed: #{$!}\n#{$@.join("\n")}"
    ensure
      schedule
    end

    def alert_validation_failed(job)
      logger.debug "#{self} alerting on invalid metrics for #{job.id}"
      Rearview::MetricsValidationMailer.validation_failed_email(job.user.email,job).deliver
    end

  end
end

