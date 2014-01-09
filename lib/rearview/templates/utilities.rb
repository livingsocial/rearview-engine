#
# Add re-usable code/functions in this module
#
class Array
  def mean
    self.sum / self.length
  end

  def median
    sorted = self.sort
    mid    = self.length / 2
    if self.length.odd?
      sorted[mid].to_f
    else
      (sorted[mid-1] + sorted[mid]).to_f / 2.0
    end
  end

  def sum
    self.inject(0) { |total, n| total + n.to_f }
  end

  def percentile(number)
    position = (number > 1) ? (number.to_f / 100) : number
    arr = self.map { |x| x || 0 }
    arr.sort[(arr.length * position) - 1]
  end
  
  def sample_variance
    return self.sum / (self.length - 1).to_f
  end

  def stdev
    return Math.sqrt(self.sample_variance)
  end
end


module MonitorUtilities
  # checks if the value is outside the limits for all of the comparison values
  def outside_limits?(value, comparison_values, limit_value, limit_type)
    diffs = comparison_values.map { |v| value - v if value && v }.compact
    diffs.length == 2 && ((limit_type == :lower && diffs.max < limit_value) || (limit_type == :upper && diffs.min > limit_value))
  end

  # percentage of minutes on this monitor that have values outside the limits
  def percentage_errors(metric, comparison_metrics, limit_value, limit_type, minutes = @minutes)
    raise "You can only define the limit type as :upper or :lower." if ![:upper, :lower].include? limit_type

    zipped_values = metric.values.zip(*(Array(comparison_metrics).map(&:values)))

    error_count = zipped_values.count do |(value, *comparison_values)|
      outside_limits?(value, comparison_values, limit_value, limit_type)
    end

    (error_count.to_f / minutes.to_f) * 100
  end

  # checks for a deployment and if found returns data before and after the deploy along with the delta
  def deploy_check(num_points, deploy, metric)
    if metric == deploy
      raise "Error: You've passed the deploy metric to be analyzed against itself, which is not a valid analysis."
    elsif metric.values.size < (num_points * 2) + 1
      raise "Error: Not enough data to evaluate. There must be #{num_points} data points before and after a deploy."
    else
      results = []
      last_deploy = deploy.values.rindex { |v| !v.nil? }

      if last_deploy
        deploy_time = deploy.entries[last_deploy].timestamp

        # If the num_points after the deploy is true then
        if metric.entries.drop_while { |entry| entry.timestamp <= deploy_time }.length == num_points
          before = metric.values.last((num_points * 2) + 1).first(num_points).sum
          after  = metric.values.last(num_points).sum
          delta  = before == 0 ? 0.0 : ((after - before) / before) * 100

          results = [metric.label, before, after, delta]
        end
      end

      results
    end
  end
  
  # determines delta in standard deviation between 2 data sets
  def collect_comparisons(metric)
    five_minute_sv = metric.values.each_slice(metric.values.length / 2).to_a.map { |pair| pair.stdev  }
    five_minute_sv.each_slice(2).to_a.map { |pair| pair.sort }.map { |pair| pair[1].to_f - pair[0].to_f }
  end

  # checks standard deviation delta for metric(s) and returns metric label delta if > deviation
  def collect_aberrations(*metrics, deviation)
    if metrics.first.values.length % 2 == 1
      raise "ERROR: collect_aberrations expects an even number of data points and you passed in #{metrics.first.values.length}"
    end
    aberrations = {}
    metrics.each do |m|
      collect_comparisons(m).inject(aberrations) { |hash, delta| hash[m.label] = delta if delta >= deviation; hash }
    end
    aberrations
  end
end # Class end