require 'spec_helper'

describe Rearview::MetricsValidator do

  context '#validate_each' do
    let(:job) { FactoryGirl.create(:job) }
    let(:metrics_validator) { Rearview::MetricsValidator.new({ attributes: [:metrics] })}
    context 'valid' do
      it 'when all metrics exists' do
        mock_client = mock(:metric_exists? => true)
        metrics_validator.stubs(:client).returns(mock_client)
        metrics_validator.validate_each(job,:metrics,job.metrics)
        expect(job.errors[:metrics]).to be_empty
      end
    end
    context 'invalid' do
      it 'when one metric does not exist' do
        job.metrics << "metric.fooey"
        mock_client = mock
        mock_client.expects(:metric_exists?).with("metric.fooey").returns(false)
        mock_client.expects(:metric_exists?).with(job.metrics.first).returns(true)
        metrics_validator.stubs(:client).returns(mock_client)
        metrics_validator.validate_each(job,:metrics,job.metrics)
        expect(job.errors[:metrics]).to include("contains an invalid metric: metric.fooey")
        expect(job.errors[:metrics]).not_to include("contains an invalid metric: #{job.metrics.first}")
      end
    end
    context 'cache' do
      context 'enabled' do
        let(:caching_validator) { Rearview::MetricsValidator.new({ attributes: [:metrics], cache: true })}
        it 'caches responses for metrics' do
          job.metrics << job.metrics.first
          mock_client = mock
          mock_client.expects(:metric_exists?).with(job.metrics.first).once.returns(true)
          caching_validator.stubs(:client).returns(mock_client)
          caching_validator.validate_each(job,:metrics,job.metrics)
          expect(job.errors[:metrics]).to be_empty
        end
      end
      context 'disabled' do
        it 'does not cache responses for metrics' do
          job.metrics << job.metrics.first
          mock_client = mock
          mock_client.expects(:metric_exists?).with(job.metrics.first).twice.returns(true)
          metrics_validator.stubs(:client).returns(mock_client)
          metrics_validator.validate_each(job,:metrics,job.metrics)
          expect(job.errors[:metrics]).to be_empty
        end
      end
    end
  end

end
