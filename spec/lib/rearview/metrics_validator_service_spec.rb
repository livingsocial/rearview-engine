require 'spec_helper'

describe Rearview::MetricsValidatorService do
  before do
    Celluloid.shutdown
    Celluloid.boot
    @service = Rearview::MetricsValidatorService.new
  end
  context '#startup' do
    it "can only be started if stopped" do
      Rearview::MetricsValidatorTask.stubs(:supervise).returns(mock)
      @service.startup
      expect { @service.startup }.to raise_error("service already started")
    end
    it "should create the supervised task" do
      Rearview::MetricsValidatorTask.expects(:supervise)
      @service.startup
    end
  end
  context '#shutdown' do
    it "can only be shutdown if started" do
      expect { @service.shutdown }.to raise_error("service not started")
    end
    it "should terminate the supervised task" do
      mock_task = mock
      mock_task.expects(:terminate).once
      Rearview::MetricsValidatorTask.stubs(:supervise).returns(stub(:actors => stub(:first => mock_task)))
      @service.startup
      @service.shutdown
    end
  end
  context '#started?' do
    it "should be true if the service is started" do
      Rearview::MetricsValidatorTask.stubs(:supervise).returns(mock)
      @service.startup
      expect(@service.started?).to be_true
    end
    it "should be false if the service is not started" do
      expect(@service.started?).to be_false
    end
  end
end

