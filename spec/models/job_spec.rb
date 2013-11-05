require 'spec_helper'

describe Rearview::Job do

  describe 'factory' do
    it 'should be valid' do
      expect { FactoryGirl.create(:job) }.not_to raise_error
      expect( FactoryGirl.create(:job).valid? ).to be_true
    end
  end

  describe 'validations' do
    it { should validate_presence_of(:cron_expr) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:metrics) }
    it { should validate_presence_of(:app_id) }
    it { should_not allow_value('abc').for(:cron_expr) }
    it { should allow_value('0 * * * * ?').for(:cron_expr) }
    it { should ensure_inclusion_of(:status).in_array(Rearview::Job::Status.values) }
    describe 'alert_keys' do
      let(:job) { create(:job) }
      it "should require a valid URI" do
        keys = ["htptptptpt://not_a_uri"]
        job.alert_keys=keys
        expect(job.valid?).to be_false
        expect(job.errors[:alert_keys]).to include("invalid URI")
      end
      it "should require it to be one of the supported schemes" do
        keys = ["http://www.google.com"]
        job.alert_keys=keys
        expect(job.valid?).to be_false
        expect(job.errors[:alert_keys]).to include("unsupported scheme")
      end
      it "should validate the scheme against the corresponding alert" do
        keys = ["pagerduty:10101010101010101010101010101010","mailto:first.last@hungrymachine.com","campfire://first.last@hungrymachine.com?token=123&room=text"]
        job.alert_keys=keys
        expect(job.valid?).to be_true
      end
      it "should detect an invalid pagerduty URI" do
        keys = ["pagerduty:abcdefg"]
        job.alert_keys=keys
        expect(job.valid?).to be_false
        expect(job.errors[:alert_keys]).to include("pagerduty URI is invalid")
      end
      it "should detect an invalid mail URI" do
        keys = ["mailto:abcdefg"]
        job.alert_keys=keys
        expect(job.valid?).to be_false
        expect(job.errors[:alert_keys]).to include("mailto URI is invalid")
      end
      it "should detect an invalid campfire URI" do
        keys = ["campfire://first.last@hungrymachine.com"]
        job.alert_keys=keys
        expect(job.valid?).to be_false
        expect(job.errors[:alert_keys]).to include("campfire URI is invalid")
      end
    end
  end
  describe 'reset' do
    it "should reset the job" do
      job = create(:job,:status=>Rearview::Job::Status::SUCCESS)
      job_data = create(:job_data,:job=>job)
      create(:job_error,:job=>job)
      create(:job_error,:job=>job,:status=>Rearview::JobError::Status::SUCCESS)
      job.expects(:schedule)
      job.expects(:unschedule)
      job.reset
      expect(job.status).to be_nil
      expect(job.job_data).to be_nil
      expect(job.job_errors.size).to eq(0)
    end
    it "should not reschedule the job if it is not active" do
      job = create(:job,:status=>Rearview::Job::Status::SUCCESS,:active=>0)
      job_data = create(:job_data,:job=>job)
      create(:job_error,:job=>job)
      create(:job_error,:job=>job,:status=>Rearview::JobError::Status::SUCCESS)
      job.expects(:schedule).never
      job.expects(:unschedule).never
      job.reset
      expect(job.status).to be_nil
      expect(job.job_data).to be_nil
      expect(job.job_errors.size).to eq(0)
    end
  end
  describe 'destroy' do
    it "should unschedule the job" do
      job = create(:job)
      monitor_service = mock
      Rearview.stubs(:monitor_service).returns(monitor_service)
      monitor_service.expects(:unschedule).with(job)
      job.destroy
    end
  end
  describe 'schedulable' do
    it "should only return jobs eligible for scheduling" do
      j1 = create(:job,:active=>false)
      j2 = create(:job,:active=>true)
      schedulable = Rearview::Job.schedulable
      expect(schedulable.count).to eq(1)
      expect(schedulable.first).to eq(j2)
    end
  end
  describe 'schedule' do
    let(:monitor_service) { mock }
    let(:job) { create(:job) }
    it "should invoke the monitoring service to schedule the job" do
      Rearview.stubs(:monitor_service).returns(monitor_service)
      monitor_service.expects(:schedule).with(job)
      job.schedule
    end
  end
  describe 'unschedule' do
    let(:monitor_service) { mock }
    let(:job) { create(:job) }
    it "should invoke the monitoring service to unschedule the job" do
      Rearview.stubs(:monitor_service).returns(monitor_service)
      monitor_service.expects(:unschedule).with(job)
      job.unschedule
    end
  end
  describe 'sync_monitor_service' do
    let(:monitor_service) { mock }
    it "should schedule an active job" do
      Rearview.stubs(:monitor_service).returns(monitor_service)
      active_job = create(:job,:active=>true)
      monitor_service.expects(:schedule).with(active_job)
      active_job.sync_monitor_service
    end
    it "should unschedule an inactive job" do
      Rearview.stubs(:monitor_service).returns(monitor_service)
      inactive_job = create(:job,:active=>false)
      monitor_service.expects(:unschedule).with(inactive_job)
      inactive_job.sync_monitor_service
    end
  end
  context 'event' do
    def mock_creation_event(job,event)
      event_data = {:job_error=>{:message=>"foo"},:monitor_results=>{:x=>:y}}
      job_errors = mock
      job_error = mock
      job_error.expects(:fire_event).with(event,event_data)
      job_errors.expects(:create).with(any_parameters).returns(job_error)
      job.expects(:job_errors).returns(job_errors)
      { :job_error=>job_error, :job_errors=>job_errors, :event_data=>event_data }
    end
    def mock_update_event(job,event)
      event_data = {:job_error=>{:message=>"foo"},:monitor_results=>{:x=>:y}}
      job_error = mock
      job_error.expects(:fire_event).with(event,event_data)
      Rearview::JobError.expects(:latest_entry).with(job).returns(job_error)
      { :job_error=>job_error, :event_data=>event_data }
    end
    context 'error' do
      it "from nil to error creates associated event" do
        job = create(:job,:status=>nil)
        objects = mock_creation_event(job,:error)
        job.fire_event(:error,objects[:event_data])
      end
      it "from success to error creates associated event" do
        job = create(:job,:status=>"success")
        objects = mock_creation_event(job,:error)
        job.fire_event(:error,objects[:event_data])
      end
      it "from error to error updates associated event" do
        job = create(:job,:status=>"error")
        objects = mock_update_event(job,:error)
        job.fire_event(:error,objects[:event_data])
      end
    end
    context 'success' do
      it "from nil to success creates associated event" do
        job = create(:job,:status=>nil)
        objects = mock_creation_event(job,:success)
        job.fire_event(:success,objects[:event_data])
      end
      it "from error to success creates associated event" do
        job = create(:job,:status=>"error")
        objects = mock_creation_event(job,:success)
        job.fire_event(:success,objects[:event_data])
      end
      it "from success to success updates associated event" do
        job = create(:job,:status=>"success")
        objects = mock_update_event(job,:success)
        job.fire_event(:success,objects[:event_data])
      end
    end
  end
end
