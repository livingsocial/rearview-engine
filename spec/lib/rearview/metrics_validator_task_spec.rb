require 'spec_helper'

describe Rearview::MetricsValidatorTask do

  before do
    now = Time.now
    Timecop.freeze(Time.local(now.year,now.mon,now.day))
  end

  context '.initialize' do
    it 'schedules itself by default' do
      Rearview::MetricsValidatorTask.any_instance.expects(:schedule)
      Rearview::MetricsValidatorTask.new('0 * * * * ?')
    end
  end

  context '#schedule' do
    it 'sets the delay to 60s if the cron expression is \'0 * * * * ?\'' do
      task = Rearview::MetricsValidatorTask.new('0 * * * * ?',false)
      task.expects(:after).with(60.0).once
      task.schedule
    end
    it 'sets the delay to 300s if the cron expression is \'0 5 * * * ?\'' do
      task = Rearview::MetricsValidatorTask.new('0 5 * * * ?',false)
      task.expects(:after).with(300.0).once
      task.schedule
    end
  end

  context '.run' do
    let(:job1_invalid) {
      job = FactoryGirl.create(:job)
      job.errors.add(:metrics,"contains an invalid metric: #{job.metrics.first}")
      job
    }
    let(:job2_valid) {
      FactoryGirl.create(:job)
    }
    let(:job3_invalid) {
      job = FactoryGirl.create(:job)
      job.errors.add(:metrics,"contains an invalid metric: #{job.metrics.first}")
      job
    }
    it 'still schedules if there is an exception' do
      Rearview::Job.stubs(:schedulable).raises(StandardError,"oops")
      task = Rearview::MetricsValidatorTask.new('0 5 * * * ?',false)
      task.expects(:schedule).once
      task.run
    end
    it 'mails alerts only for jobs with invalid metrics' do
      Rearview::Job.stubs(:schedulable).returns(mock(:load => [job1_invalid,job2_valid,job3_invalid]))
      Rearview::MetricsValidator.any_instance.stubs(:validate_each)
      task = Rearview::MetricsValidatorTask.new('0 5 * * * ?',false)
      task.expects(:schedule).once
      task.expects(:alert_validation_failed).with(job1_invalid).once
      task.expects(:alert_validation_failed).with(job2_valid).never
      task.expects(:alert_validation_failed).with(job3_invalid).once
      task.run
    end
  end

end
