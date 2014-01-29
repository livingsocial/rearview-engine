require 'spec_helper'

describe Rearview::Configuration do

  before do
    Rearview::Configuration.any_instance.stubs(:validate_sandbox_execution).returns(true)
  end

  let(:config) { Rearview::Configuration.new }

  context 'validation' do
    it { should validate_presence_of(:default_from) }
    it { should validate_presence_of(:sandbox_exec) }
    it { should validate_presence_of(:sandbox_timeout) }
    it { should validate_presence_of(:default_url_options) }
    it { should validate_presence_of(:authentication) }
    it { should validate_numericality_of(:sandbox_timeout).is_greater_than(4) }
    context 'sandbox_dir' do
      it { should validate_presence_of(:sandbox_dir) }
      it "should be a directory" do
        config.sandbox_dir="/__not_likely__"
        config.valid?
        expect(config.errors[:sandbox_dir]).to include("is not a directory")
        config.sandbox_dir = File.dirname(__FILE__)
        config.valid?
        expect(config.errors[:sandbox_dir]).to be_empty
      end
    end
    context 'graphite_connection' do
      it { should validate_presence_of(:graphite_connection) }
      it "should require url option to be a valid url" do
        config.graphite_connection = { url: 'ssh://fooblah' }
        config.valid?
        expect(config.errors[:graphite_connection]).to include("does not contain a valid URL")
      end
      it "should require url option to be present" do
        config.graphite_connection = { url: nil }
        config.valid?
        expect(config.errors[:graphite_connection]).to include("graphite URL can't be blank")
      end
      pending do
        it "should require url option to be reachable" do
          config.graphite_connection = { url: 'http://graphite6.graphitehosting.com' }
          config.valid?
          mock_client = mock(:reachable? => false)
          Graphite::Client.expects(:new).returns(mock_client)
          expect(config.errors[:graphite_connection]).to include("graphite cannot be reached")
        end
      end
    end
    context 'pagerduty_url' do
      it { should validate_presence_of(:pagerduty_url) }
      it "should require pagerduty_url to be a url" do
        config.pagerduty_url="ftp://fooblah"
        config.valid?
        expect(config.errors[:pagerduty_url]).to include("is not a valid URL")
        config.pagerduty_url="HTTPS://fooblah"
        config.valid?
        expect(config.errors[:pagerduty_url]).to be_empty
      end
    end
    context 'statsd_connection' do
      it "should be present if stats are enabled" do
        config.enable_stats = false
        config.valid?
        expect(config.errors[:statsd_connection]).to be_empty
        config.enable_stats = true
        config.valid?
        expect(config.errors[:statsd_connection]).to include("can't be blank")
      end
    end
    context 'metrics_validator_schedule' do
      it { should_not allow_value('abc').for(:metrics_validator_schedule) }
      it { should allow_value('0 * * * * ?').for(:metrics_validator_schedule) }
      it "should be present if metrics_validator is enabled" do
        config.enable_metrics_validator = false
        config.valid?
        expect(config.errors[:metrics_validator_schedule]).to be_empty
        config.enable_metrics_validator = true
        config.metrics_validator_schedule = nil
        config.valid?
        expect(config.errors[:metrics_validator_schedule]).to include("can't be blank")
      end
    end
  end

  context '.new' do
    it 'sets sensible defaults' do
      expect(config.default_from).to eq("rearview@localhost")
      expect(config.pagerduty_url).to eq("https://events.pagerduty.com/generic/2010-04-15/create_event.json")
      expect(config.sandbox_timeout).to eq(5)
      expect(config.enable_alerts).to be_true
      expect(config.preload_jobs).to be_true
      expect(config.enable_monitor).to be_true
      expect(config.enable_stats).to be_false
      expect(config.verify).to be_false
      expect(config.graphite_connection).to eq({})
      expect(config.authentication).to eq({strategy: :database})
      expect(config.default_url_options).to eq({:host=>"localhost", :port=>"3000"})
    end
  end

  context '#with_argv' do
    it 'processes args as command line options' do
      expect { config.with_argv(["--no-preload","--no-alerts","--no-monitor"]) }.not_to raise_error
      expect(config.preload_jobs?).to be_false
      expect(config.monitor_enabled?).to be_false
      expect(config.alerts_enabled?).to be_false
    end
  end

  context '#dump' do
    it 'dumps a stringy version of the configuration' do
      expect(config.dump).not_to be_empty
    end
  end

end

