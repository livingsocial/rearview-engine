module Graphite
  class RawParser
    ## returns an array of arrays of pairs with 2 elements timestamp and value (may be nil)
    def self.parse(lines)
      lines.strip.split("\n").map do |line|
        metric, startTime, endTime, interval, dataStr = /(.*),(\d+),(\d+),(\d+)\|(.*)/.match(line)[1..-1]
        data = dataStr.split(",")
        0.upto(data.length - 1).map do |i|
          value = data[i]
          {
            :metric    => metric,
            :timestamp => startTime.to_i + (interval.to_i * i),
            :value     => !value.nil?  ? value.to_f : value
          }
        end
      end
    end
  end
end
