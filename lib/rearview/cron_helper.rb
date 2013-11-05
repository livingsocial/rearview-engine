java_import 'org.quartz.CronExpression'

module Rearview
  module CronHelper
    class << self
      include Rearview::Logger
      def next_valid_time_after(expr)
        now = Time.now
        java_now = java.util.Date.new(now.to_i*1000)
        next_valid_time = CronExpression.new(expr).getNextValidTimeAfter(java_now)
        get_time = next_valid_time.getTime / 1000
        next_time = Time.at(get_time)
        # Use (now.to_i*1000) so we can use timecop for testing...
        # next_time = Time.at(CronExpression.new(expr).getNextValidTimeAfter(java.util.Date.new(now.to_i*1000)).getTime / 1000)
        logger.debug "#{self} expr:\"#{expr}\" now:\"#{now}\" java_now:\"#{java_now}\" next_valid_time:\"#{next_valid_time}\" get_time:\"#{get_time}\" next_time:\"#{next_time}\" delay:#{next_time - now}"
        next_time - now
      end
      def valid_expression?(expr)
        CronExpression.is_valid_expression(expr)
      end
    end
  end
end

