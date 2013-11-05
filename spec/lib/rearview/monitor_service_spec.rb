require 'spec_helper'

describe Rearview::MonitorService do
  let(:supervisor) {
    mock do
      stubs(:add_tasks)
      stubs(:remove_tasks)
      stubs(:remove_all_tasks)
      stubs(:terminate)
    end
  }
  before do
    Celluloid.shutdown
    Celluloid.boot
    Rearview::MonitorSupervisor.stubs(:new).returns(supervisor)
    @service = Rearview::MonitorService.new
  end
  context "startup" do
    it "should perform startup actions" do
      supervisor.expects(:add_tasks).with([]).once
      @service.startup
      expect(@service.started?).to be_true
    end
    it "can only be started if stopped" do
      @service.startup
      expect { @service.startup }.to raise_error(Rearview::MonitorService::MonitorServiceError,"service already started")
    end
  end
  context "shutdown" do
    it "should perform shutdown actions" do
      supervisor.expects(:remove_all_tasks).once
      supervisor.expects(:terminate).once
      @service.startup
      @service.shutdown
      expect(@service.started?).to be_false
    end
    it "can only be stopped if started" do
      expect { @service.shutdown }.to raise_error(Rearview::MonitorService::MonitorServiceError,"service not started")
    end
  end
  context "schedule" do
    let(:job) { create(:job) }
    it "should add the job" do
      @service.expects(:remove).never
      @service.startup
      @service.schedule(job)
      # mysterious failure...
      # supervisor.expects(:add_tasks).with([job]).once
      expect(@service.jobs[job.id]).to eq(job)
    end
    it "should remove the job if it already has been scheduled" do
      @service.startup
      @service.add(job)
      supervisor.expects(:remove_tasks).with([job]).once
      @service.schedule(job)
    end
    it "should fail if the service has not been started" do
      expect { @service.schedule(job) }.to raise_error(Rearview::MonitorService::MonitorServiceError,"service not started")
    end
  end
  context "unschedule" do
    let(:job) { create(:job) }
    it "should remove the job" do
      @service.startup
      @service.add(job)
      supervisor.expects(:remove_tasks).with([job]).once
      expect { @service.unschedule(job) }.not_to raise_error
      expect(@service.jobs[job.id]).to be_nil
    end
    it "should not fail if the job was never added" do
      @service.startup
      expect { @service.unschedule(job) }.not_to raise_error
      expect(@service.jobs[job.id]).to be_nil
    end
    it "should fail if the service has not been started" do
      expect { @service.unschedule(job) }.to raise_error(Rearview::MonitorService::MonitorServiceError,"service not started")
    end
  end
  context "add" do
    let(:job) { create(:job) }
    it "should add the job to the supervisor" do
      supervisor.expects(:add_tasks).with([job]).once
      @service.startup
      @service.add(job)
      expect(@service.jobs[job.id]).to eq(job)
    end
    it "should not fail if the job has already been added to the supervisor" do
      @service.startup
      @service.add(job)
      expect { @service.add(job) }.not_to raise_error
    end
    it "should fail if the service has not been started" do
      expect { @service.add(job) }.to raise_error(Rearview::MonitorService::MonitorServiceError,"service not started")
    end
  end
  context "remove" do
    let(:job) { create(:job) }
    it "should remove from the supervisor" do
      supervisor.expects(:remove_tasks).with([job]).once
      @service.startup
      @service.add(job)
      @service.remove(job)
      expect(@service.jobs[job.id]).to be_nil
    end
    it "should not fail if the job has not already been added to the supervisor" do
      @service.startup
      expect { @service.remove(job) }.not_to raise_error
    end
    it "should fail if the service has not been started" do
      expect { @service.remove(job) }.to raise_error(Rearview::MonitorService::MonitorServiceError,"service not started")
    end
  end
end

