require 'spec_helper'

describe Rearview::Statsd do
  context '.initialize' do
    before(:all) do
      Rearview.config.statsd_connection = { host: 'myhost', port: 123, namespace: 'mynamespace' }
    end
    let(:statsd) { Rearview::Statsd.new }
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

end
