require 'spec_helper'

describe Rearview::StatsTask do

  context '.initialize' do
    it "sets the default delay to 120s" do
      Rearview::StatsTask.any_instance.stubs(:schedule)
      stats_task = Rearview::StatsTask.new
      Rearview::Statsd.stubs(:new).returns(mock)
      expect(stats_task.delay).to eq(120)
    end
    it "sets the batch size correctly" do
      Rearview::StatsTask.any_instance.stubs(:schedule)
      statsd = mock
      statsd.expects(:batch_size=).with(12)
      Rearview::Statsd.stubs(:new).returns(statsd)
      stats_task = Rearview::StatsTask.new
    end
    it "schedules itself by default" do
      statsd = mock
      statsd.expects(:batch_size=).with(anything)
      Rearview::Statsd.stubs(:new).returns(statsd)
      Rearview::StatsTask.any_instance.expects(:schedule)
      stats_task = Rearview::StatsTask.new
    end
  end

  context '#schedule' do
    it "sets the timer delay" do
      stats_task = Rearview::StatsTask.new(120,false)
      stats_task.expects(:after).with(120)
      stats_task.schedule
    end
  end

  context '#run' do
    it "sends a batch request to statsd" do
      stats_task = Rearview::StatsTask.new(120,false)
      stats_task.statsd.expects(:batch)
      stats_task.run
    end
    it "sends the correct stats" do
      statsd = mock
      batch = mock
      statsd.expects(:batch_size=)
      Rearview::Statsd.stubs(:new).returns(statsd)
      stats_task = Rearview::StatsTask.new(120,false)
      statsd.expects(:batch).yields(batch)
      batch.expects(:gauge).with('vm.total_memory',any_parameters)
      batch.expects(:gauge).with('vm.free_memory',any_parameters)
      batch.expects(:gauge).with('vm.max_memory',any_parameters)
      batch.expects(:gauge).with('vm.heap.committed',any_parameters)
      batch.expects(:gauge).with('vm.heap.init',any_parameters)
      batch.expects(:gauge).with('vm.heap.max',any_parameters)
      batch.expects(:gauge).with('vm.heap.used',any_parameters)
      batch.expects(:gauge).with('vm.non_heap.committed',any_parameters)
      batch.expects(:gauge).with('vm.non_heap.init',any_parameters)
      batch.expects(:gauge).with('vm.non_heap.max',any_parameters)
      batch.expects(:gauge).with('vm.non_heap.used',any_parameters)
      batch.expects(:gauge).with('monitor.total',any_parameters)
      stats_task.run
    end
  end

end

