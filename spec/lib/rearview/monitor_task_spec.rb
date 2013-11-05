require 'spec_helper'

describe Rearview::MonitorTask do

  before do
    # Celluloid.shutdown
    # Celluloid.boot
    # @task = Rearview::MonitorTask.new(create(:job),false)
  end

  context "run" do
    it "should gracefully handle no result from monitor runner" do
      pending "figure out how to test this..."
      # Rearview::MonitorRunner.stubs(:run).returns(nil)
      # @task.expects(:schedule).once
      # @task.run
    end
    it "only sends alerts if results are not success" do
      pending "figure out how to test this..."
      # Rearview::MonitorRunner.stubs(:run).returns(nil)
      # @task.stubs(:process_results).returns("success")
      # @task.stubs(:schedule).returns(true)
      # @task.expects(:send_alerts).never
      # @task.run
    end
  end

end

