require 'spec_helper'

describe Rearview::Statsd do
  before(:all) do
    Rearview.config.statsd_connection = { host: 'myhost', port: 123, namespace: 'mynamespace' }
  end
  let(:statsd) { Rearview::Statsd.new }
  context '.initialize' do
    it "sets the port from Rearview::Configuration" do
      expect(statsd.port).to eq(123)
    end
    it "sets the host from Rearview::Configuration" do
      expect(statsd.host).to eq('myhost')
    end
    it "sets the namespace from Rearview::Configuration" do
      expect(statsd.namespace).to eq('mynamespace')
    end
  end
  context '.statsd' do
    it "returns a shared instance" do
      expect(Rearview::Statsd.statsd).to eq(Rearview::Statsd.statsd)
      expect(Rearview::Statsd.statsd).not_to be_nil
    end
  end
  context '.report' do
    it "will yield to the block if stats are enabled" do
      Rearview.config.stubs(:stats_enabled?).returns(true)
      block_yielded = false
      Rearview::Statsd.report { |stats| block_yielded = true }
      expect(block_yielded).to be_true
    end
    it "will not yield to the block if stats are disabled" do
      Rearview.config.stubs(:stats_enabled?).returns(false)
      block_yielded = false
      Rearview::Statsd.report { |stats| block_yielded = true }
      expect(block_yielded).to be_false
    end
  end
end
