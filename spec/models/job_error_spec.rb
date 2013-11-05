require 'spec_helper'

describe Rearview::JobError do

  let(:dashboard) { create(:dashboard) }
  let(:job) { create(:job,:dashboard => dashboard) }
  let(:alert_handler) { mock }
  let(:event_data) { {:monitor_results=>{:x=>:y}} }

  describe 'factory' do
    it 'should be valid' do
      expect { FactoryGirl.create(:job_error) }.not_to raise_error
      expect( FactoryGirl.create(:job_error).valid? ).to be_true
    end
  end

  describe 'validations' do
    it { should validate_presence_of(:job_id) }
    it { should ensure_inclusion_of(:status).in_array(Rearview::JobError::Status.values) }
  end

  describe 'create_alert' do
    it "should sends alerts through the alerts handler" do
      Rearview::AlertsHandler.expects(:new).with(job,event_data[:monitor_results]).returns(alert_handler)
      alert_handler.expects(:run).once
      job_error = create(:job_error,:job=>job)
      job_error.expects(:save!).once
      job_error.expects(:last_alerted_at=).once
      job_error.event_data = event_data
      job_error.create_alert(nil)
    end
  end

  describe 'update_alert' do
    it "should sends alerts when last_alerted_at is empty" do
      Rearview::AlertsHandler.expects(:new).with(job,event_data[:monitor_results]).returns(alert_handler)
      alert_handler.expects(:run).once
      job_error = create(:job_error,:job=>job)
      job_error.expects(:save!).once
      job_error.expects(:last_alerted_at=).once
      job_error.event_data = event_data
      job_error.update_alert(nil)
    end
    it "should sends alerts when the last_alerted_at is past the error timeout" do
      Rearview::AlertsHandler.expects(:new).with(job,event_data[:monitor_results]).returns(alert_handler)
      alert_handler.expects(:run).once
      job_error = create(:job_error,:job=>job,:last_alerted_at=>1.day.ago)
      job_error.expects(:save!).once
      job_error.expects(:last_alerted_at=).once
      job_error.event_data = event_data
      job_error.update_alert(nil)
    end
    it "should not send alerts when the last_alerted_at is not past the error timeout" do
      Rearview::AlertsHandler.expects(:new).with(job,event_data[:monitor_results]).never
      alert_handler.expects(:run).never
      job_error = create(:job_error,:job=>job,:last_alerted_at=>1.minutes.ago)
      job_error.expects(:save!).never
      job_error.expects(:last_alerted_at=).never
      job_error.event_data = event_data
      job_error.update_alert(nil)
    end
  end

  describe 'last_error' do
    it "should return the last error" do
      job_error = create(:job_error,:job=>job,:created_at=>1.day.ago,:status=>Rearview::JobError::Status::FAILED)
      last_error = Rearview::JobError.last_error(job.id)
      expect(last_error).to eq(job_error)
    end
    it "shouldn't return non-errors" do
      job_error = create(:job_error,:job=>job,:created_at=>1.day.ago,:status=>Rearview::JobError::Status::SUCCESS)
      last_error = Rearview::JobError.last_error(job.id)
      expect(last_error).to be_nil
    end
  end

  describe 'latest_entry' do
    it "should return the latest entry" do
      je1 = create(:job_error,:job=>job,:created_at=>1.day.ago,:status=>Rearview::JobError::Status::FAILED)
      je2 = create(:job_error,:job=>job,:created_at=>2.day.ago,:status=>Rearview::JobError::Status::FAILED)
      expect(Rearview::JobError.latest_entry(job)).to eq(je1)
    end
  end

  describe 'application_errors' do
    before do
      create(:job_error,:job=>job,:created_at=>1.day.ago,:status=>Rearview::JobError::Status::SUCCESS)
      create(:job_error,:job=>job,:created_at=>1.day.ago,:status=>Rearview::JobError::Status::FAILED)
      create(:job_error,:job=>job,:created_at=>1.day.ago,:status=>Rearview::JobError::Status::ERROR)
      create(:job_error,:job=>job,:created_at=>1.day.ago,:status=>Rearview::JobError::Status::GRAPHITE_ERROR)
    end
    it "should include errors for the application" do
      errors = Rearview::JobError.application_errors(dashboard.id)
      expect(errors.size).to eq(4)
    end
  end

  describe 'search' do
    before do
      Timecop.freeze(Time.now)
      create(:job_error,:job=>job,:created_at=>1.day.ago)
      create(:job_error,:job=>job,:created_at=>2.day.ago)
      create(:job_error,:job=>job,:created_at=>3.day.ago)
      create(:job_error,:job=>job,:created_at=>4.day.ago)
      create(:job_error,:job=>job,:created_at=>5.day.ago)
      create(:job_error,:job=>job,:created_at=>6.day.ago)
      create(:job_error,:job=>job,:created_at=>7.day.ago)
    end
    after do
      Timecop.return
    end
    it "should default order by created descending" do
      job_errors = Rearview::JobError.search(:id=>job.id)
      expect(job_errors.first.created_at.to_i).to eq(1.day.ago.to_i)
    end
    it "should filter by limit" do
      job_errors = Rearview::JobError.search(:id=>job.id,:limit=>3)
      expect(job_errors.size).to eq(3)
    end
    it "should filter by limit and offset" do
      job_errors = Rearview::JobError.search(:id=>job.id,:limit=>3,:offset=>1)
      expect(job_errors.size).to eq(3)
      expect(job_errors.first.created_at.to_i).to eq(2.day.ago.to_i)
    end
    it "should filter by start_date of created" do
      job_errors = Rearview::JobError.search(:id=>job.id,:start_date=>2.day.ago)
      expect(job_errors.size).to eq(2)
      expect(job_errors.first.created_at.to_i).to eq(2.day.ago.to_i)
      expect(job_errors.last.created_at.to_i).to eq(1.day.ago.to_i)
    end
    it "should filter by end_date of created" do
      job_errors = Rearview::JobError.search(:id=>job.id,:end_date=>6.day.ago)
      expect(job_errors.size).to eq(2)
      expect(job_errors.first.created_at.to_i).to eq(7.day.ago.to_i)
      expect(job_errors.last.created_at.to_i).to eq(6.day.ago.to_i)
    end
    it "should filter by start_date and end_date of created" do
      job_errors = Rearview::JobError.search(:id=>job.id,:start_date=>5.day.ago, :end_date=>1.day.ago)
      expect(job_errors.size).to eq(5)
      expect(job_errors.first.created_at.to_i).to eq(5.day.ago.to_i)
      expect(job_errors.last.created_at.to_i).to eq(1.day.ago.to_i)
    end
  end

  describe 'calculate_durations' do

    before do
      Timecop.freeze(Time.now)
    end

    after do
      Timecop.return
    end

    context 'timeline' do
      def create_timeline(*args)
        offset = args.count
        args.map do |status_sym|
          status = case status_sym
                   when :s
                     Rearview::JobError::Status::SUCCESS
                   when :e
                     Rearview::JobError::Status::ERROR
                   else
                     nil
                   end
          job_error = create(:job_error,:job=>job,:status=>status,:created_at=>Time.now - offset.minute)
          offset -= 1
          job_error
        end
      end
      it 'is empty' do
        expect { Rearview::JobError.calculate_durations([]) }.not_to raise_error
      end
      it 'is {success}' do
        timeline = create_timeline(:s)
        Rearview::JobError.calculate_durations(timeline)
        expect(timeline.first.end_date).to be_nil
      end
      it 'is {error}' do
        timeline = create_timeline(:e)
        Rearview::JobError.calculate_durations(timeline)
        expect(timeline.first.end_date).to be_nil
      end
      it 'is {error,success}' do
        timeline = create_timeline(:e,:s)
        Rearview::JobError.calculate_durations(timeline)
        expect(timeline.first.end_date).to eq(timeline.last.created_at.utc.to_i)
        expect(timeline.last.end_date).to be_nil
      end
      it 'is {success,error}' do
        timeline = create_timeline(:s,:e)
        Rearview::JobError.calculate_durations(timeline)
        expect(timeline.first.end_date).to be_nil
        expect(timeline.last.end_date).to be_nil
      end
      it 'is {success,error,success}' do
        timeline = create_timeline(:s,:e,:s)
        Rearview::JobError.calculate_durations(timeline)
        expect(timeline[0].end_date).to be_nil
        expect(timeline[1].end_date).to eq(timeline.last.created_at.utc.to_i)
        expect(timeline[2].end_date).to be_nil
      end
      it 'returns results with success entries filtered out' do
        timeline = create_timeline(:s,:e,:e,:s)
        results = Rearview::JobError.calculate_durations(timeline)
        expect(results.size).to eq(2)
        expect(results.map(&:status)).not_to include(Rearview::JobError::Status::SUCCESS)
      end
    end

  end
end

