require 'json'

module Rearview
  class StatsTask
    class StatsTaskError < StandardError; end;
    include Celluloid
    include Celluloid::Logger
    attr_reader :delay, :statsd
    def initialize(delay=120,start=true)
      @delay = delay
      @statsd = Rearview::Statsd.new
      # This number is not documented well. The batch size is actually the max
      # number of batch calls allowed, before the UDP message is sent. Anything
      # after this value is quietly dropped. However, keep in mind that the
      # safest max UDP message size is 512.
      #
      # So make sure that batch_size * 8bytes/per int < 512
      @statsd.batch_size = 11
      schedule if start
    end

    def schedule
      debug "#{self} schedule"
      @timer = after(@delay) { self.run }
    end

    def run
      debug "#{self} run"
      vm = Rearview::Vm.new
      @statsd.batch do |batch|
        batch.gauge('vm.total_memory',vm.total_memory.bytes_to_kilobytes)
        batch.gauge('vm.free_memory',vm.free_memory.bytes_to_kilobytes)
        batch.gauge('vm.max_memory',vm.max_memory.bytes_to_kilobytes)
        batch.gauge('vm.heap.committed',vm.heap.committed.bytes_to_kilobytes)
        batch.gauge('vm.heap.init',vm.heap.init.bytes_to_kilobytes)
        batch.gauge('vm.heap.max',vm.heap.max.bytes_to_kilobytes)
        batch.gauge('vm.heap.used',vm.heap.used.bytes_to_kilobytes)
        batch.gauge('vm.non_heap.committed',vm.non_heap.committed.bytes_to_kilobytes)
        batch.gauge('vm.non_heap.init',vm.non_heap.init.bytes_to_kilobytes)
        batch.gauge('vm.non_heap.max',vm.non_heap.max.bytes_to_kilobytes)
        batch.gauge('vm.non_heap.used',vm.non_heap.used.bytes_to_kilobytes)
      end
    rescue
      error "#{self} run failed: #{$!}\n#{$@.join("\n")}"
    ensure
      schedule
    end

  end
end

