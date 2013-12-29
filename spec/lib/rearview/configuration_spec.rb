require 'spec_helper'

describe Rearview::Configuration do

  before do
    Rearview::Configuration.any_instance.stubs(:validate_sandbox_execution).returns(true)
  end

  let(:config) { Rearview::Configuration.new }

  context 'validation' do
    it { should validate_presence_of(:graphite_url) }
    it { should validate_presence_of(:pagerduty_url) }
    it { should validate_presence_of(:default_from) }
    it { should validate_presence_of(:sandbox_dir) }
    it { should validate_presence_of(:sandbox_exec) }
    it { should validate_presence_of(:sandbox_timeout) }
    it { should validate_presence_of(:default_url_options) }
    it { should validate_numericality_of(:sandbox_timeout).is_greater_than(4) }
    it "should requre sandbox_dir to be a directory" do
      config.sandbox_dir="/__not_likely__"
      config.valid?
      expect(config.errors[:sandbox_dir]).to include("is not a directory")
      config.sandbox_dir = File.dirname(__FILE__)
      config.valid?
      expect(config.errors[:sandbox_dir]).to be_empty
    end
    it "should require graphite_url to be a url" do
      response = stub(code: 200)
      HTTParty.stubs(:get).returns(response)
      config.graphite_url="ssh://fooblah"
      config.valid?
      expect(config.errors[:graphite_url]).to include("is not a valid URL")
      config.graphite_url="fooblah"
      config.valid?
      expect(config.errors[:graphite_url]).to include("is not a valid URL")
      config.graphite_url="http://fooblah.com"
      config.valid?
      expect(config.errors[:graphite_url]).to be_empty
    end
    it "should require pagerduty_url to be a url" do
      config.pagerduty_url="ftp://fooblah"
      config.valid?
      expect(config.errors[:pagerduty_url]).to include("is not a valid URL")
      config.pagerduty_url="HTTPS://fooblah"
      config.valid?
      expect(config.errors[:pagerduty_url]).to be_empty
    end
    it "should require graphite_url to be reachable" do
      response = stub(code: 400)
      HTTParty.expects(:get).with("http://graphite.mycompany-unreachable.com").returns(response)
      config.graphite_url="http://graphite.mycompany-unreachable.com"
      config.valid?
      expect(config.errors[:graphite_url]).to include("is not a reachable URL")
      response = stub(code: 200)
      HTTParty.expects(:get).with("http://graphite.mycompany.com").returns(response)
      config.graphite_url="http://graphite.mycompany.com"
      config.valid?
      expect(config.errors[:graphite_url]).to be_empty
    end
    pending "should require sanbox_exec to be executable"
  end

  context '.new' do
    it 'sets sensible defaults' do
      expect(config.default_from).to eq("rearview@localhost")
      expect(config.pagerduty_url).to eq("https://events.pagerduty.com/generic/2010-04-15/create_event.json")
      expect(config.sandbox_timeout).to eq(5)
      expect(config.enable_alerts).to be_true
      expect(config.preload_jobs).to be_true
      expect(config.enable_monitor).to be_true
      expect(config.verify).to be_false
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

