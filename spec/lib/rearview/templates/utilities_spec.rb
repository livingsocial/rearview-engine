require 'spec_helper'
require 'rearview/templates/utilities'

RSpec.configure do |c|
  c.include MonitorUtilities
end

class TimeSeries
  attr_reader :entries
  attr_reader :label

  def initialize(label, ts)
    @label = label
    @entries = ts
  end
      
  def values
    @entries
  end
end

describe "utility method" do
  let(:today) { TimeSeries.new("today", [1, 3, 0, 1, 0, 0, 0, 0, 1, 0]) }
  let(:one_week) { TimeSeries.new("one week", [-0.004, -0.003, -0.002, -0.001, 0.001, 0.002, 0.003, 0.004, 0.005, 0.006]) }
  let(:two_weeks) { TimeSeries.new("two weeks", [0.279, 0.285, 0.292, 0.300, 0.308, 0.316, 0.325, 0.334, 0.342, 0.351]) }
  let(:today_nil) { TimeSeries.new("today with nil", [1, 3, nil, 1, nil, nil, nil, nil, 1, 0]) }
  let(:one_week_nil) { TimeSeries.new("one week with nil", [-0.004, nil, -0.002, -0.001, 0.001, 0.002, 0.003, 0.004, nil, 0.006]) }

  describe 'percentage_errors' do
    it "returns correct percentages for lower limit check" do
      result = percentage_errors(today, [one_week, two_weeks], 1, :lower, 10)
      expect(result.round).to eq(70)
    end
    
    it "returns correct percentages for lower limit check with nils" do
      result = percentage_errors(today_nil, [one_week_nil, two_weeks], 1, :lower, 10)
      expect(result.round).to eq(10)
    end
    
    it "returns correct percentages for upper limit check" do
      result = percentage_errors(today, [one_week, two_weeks], -0.05, :upper, 10)
      expect(result.round).to eq(40)
    end
    
    it "returns correct percentages for upper limit check with nils" do
      result = percentage_errors(today_nil, [one_week_nil, two_weeks], -0.0, :upper, 10)
      expect(result.round).to eq(20)
    end
    
    it "accepts only upper or lower for limit type" do
      expect { percentage_errors(today, [one_week, two_weeks], 1, :right_hand, 10) }.to raise_error
    end
    
    it "accepts a single comparison metric without requiring an array" do
      expect { percentage_errors(today, one_week, 1, :lower, 10) }.to_not raise_error
    end
  end
  
  metric_a = File.open("spec/data/metric_a.dat").map { |line| line.to_i }
  metric_b = File.open("spec/data/metric_b.dat").map { |line| line.to_i }
  let(:all_created) { TimeSeries.new("All Purchases Created in the last hour", metric_a) }
  let(:local_created) { TimeSeries.new("Local Purchases Created in the last hour", metric_b) }

  describe 'collect_aberations' do
    it "returns correct error for single metric" do
      monitor_expr = <<-'eos'
        puts @a
      eos
      result = collect_aberrations(all_created, 0)
      expect(result).to eq({"All Purchases Created in the last hour"=>0.3505384991636653})
    end
  
    it "returns correct errors for multiple metrics" do
      result = collect_aberrations(all_created, local_created, 0.36)
      expect(result).to eq({"Local Purchases Created in the last hour"=>0.40808960944909956})
    end
  end
end