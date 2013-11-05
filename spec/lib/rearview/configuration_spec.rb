require 'spec_helper'

describe Rearview::Configuration do

  context 'initialize' do
    it 'sets defaults' do
      config = Rearview::Configuration.new
      expect(config.default_from.present?).to be_true
      expect(config.graphite_url.present?).to be_true
      expect(config.pagerduty_url.present?).to be_true
      expect(config.sandbox_timeout.present?).to be_true
      expect(config.enable_alerts.present?).to be_true
      expect(config.preload_jobs.present?).to be_true
      expect(config.enable_monitor.present?).to be_true
    end
  end

  context 'with_argv' do
    it 'processes args as command line options' do
      config = Rearview::Configuration.new
      expect { config.with_argv(["--no-preload","--no-alerts","--no-monitor"]) }.not_to raise_error
      expect(config.preload_jobs?).to be_false
      expect(config.monitor_enabled?).to be_false
      expect(config.alerts_enabled?).to be_false
    end
  end

end

