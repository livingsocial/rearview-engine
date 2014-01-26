require 'spec_helper'

describe Rearview::MonitorRunner, :travis=>true do

  artifact1 = Graphite::RawParser.parse open("spec/data/monitor.dat").read
  artifact2 = Graphite::RawParser.parse open("spec/data/test.dat").read
  artifact3 = Graphite::RawParser.parse open("spec/data/large_set.dat").read

  context 'create_from_to_dates' do
    before do
      Timecop.freeze(Time.now)
    end
    after do
      Timecop.return
    end
    it "conversion from minutes to an integer doesn't raise an error" do
      expect { Rearview::MonitorRunner.create_from_to_dates("60","now") }.to_not raise_error
    end
    it "sets the to date to current time less 1 minute if time is nil" do
      from_to = Rearview::MonitorRunner.create_from_to_dates(nil,nil)
      expect(from_to.last).to eq((Time.now.gmtime - 1.minutes).strftime('%H:%M_%Y%m%d'))
    end
    it "sets the to date to current time less 1 minute if time is now" do
      from_to = Rearview::MonitorRunner.create_from_to_dates(nil,"now")
      expect(from_to.last).to eq((Time.now.gmtime - 1.minutes).strftime('%H:%M_%Y%m%d'))
    end
    it "subtracts a minute from to date if it is not nil or now" do
      from_to = Rearview::MonitorRunner.create_from_to_dates(nil,'10/01/2013 12:01')
      expect(from_to.last).to eq('12:00_20131001')
    end
  end

  context 'eval' do
    it "supports adhoc evaluation" do
      monitor_expr = <<-'eos'
        puts @timeseries.length
        puts @a.values.length
      eos
      result = Rearview::MonitorRunner.eval(artifact1, monitor_expr)
      expect(result[:monitor_output][:status]).to eq("success")
    end

    it "supports generating instance vars for very large datasets" do
      monitor_expr = <<-'eos'
        puts @timeseries.length
        puts @a.values.length
      eos
      result = Rearview::MonitorRunner.eval(artifact3, monitor_expr)
      expect(result[:monitor_output][:status]).to eq("success")
    end

    it "supports failure custom message" do
      monitor_expr = <<-'eos'
        total = @a.values.inject(0) { |accum, v| accum + v.to_f }
        raise "Custom failure message count = #{total}"
      eos
      result = Rearview::MonitorRunner.eval(artifact1, monitor_expr)
      expect(result[:monitor_output][:status]).to eq("failed")
      expect(result[:monitor_output][:output]).to eq("Custom failure message count = 62.0")
    end
  end

  context 'normalize_results' do
    let(:empty_graph_data_results) {
      {
        :monitor_output =>
          {
            :status=>"success",
            :output=>"empty_graph_data_results_output",
            :message=>nil,
            :data=>[],
            :graph_data=>[]
          }
      }
    }
    let(:nil_graph_data_results) {
      {
        :monitor_output =>
          {
            :status=>"success",
            :output=>"nil_graph_data_results_output",
            :message=>nil,
            :data=>[],
            :graph_data=>nil
          }
      }
    }
    let(:error_results) {
      {:output=>
        {
          :status=>"error",
          :output=>{:status=>"error", :output=>"initialize: name or service not known", :graph_data=>nil},
          :message=>"initialize: name or service not known", :data=>nil
        }
      }
    }
    let(:single_graph_data_results) {
      {:monitor_output=>
       {:status=>"success",
        :output=>"single_graph_data_results_output",
        :message=>nil,
        :data=>[],
        :graph_data=>[
          {"stats_counts.cupcake.web_traffic.impression"=>[[1368635510, 49.0], [1368635520, 53.0], [1368635530, 62.0], [1368635540, 63.0], [1368635550, 63.0], [1368635560, 60.0], [1368635570, 0.0], [1368635580, nil]]}]}}
    }
    let(:multi_graph_data_results) {
      {:monitor_output=>
       {:status=>"success",
        :output=>"multi_graph_data_results_output",
        :message=>nil,
        :data=>[],
        :graph_data=>[
          {"drawAsInfinite(deploy)"=>[[1368723670, 0.0], [1368723730, 0.0 ]]},
          {"Successful Web Logins"=>[[1368723670, 84.0], [1368723730, 98.0]]}]
       }
      }
    }

    it 'normalizes monitor output with multi graph data results' do
      normalized = Rearview::MonitorRunner.normalize_results(multi_graph_data_results)
      expect(normalized).to eq({
        status: Rearview::Job::Status::SUCCESS,
        output: "multi_graph_data_results_output",
        graph_data: {
          "drawAsInfinite(deploy)" => [[1368723670, 0.0], [1368723730, 0.0 ]],
          "Successful Web Logins" => [[1368723670, 84.0], [1368723730, 98.0]]
        }
      })
    end
    it 'normalizes monitor output with single graph data results' do
      normalized = Rearview::MonitorRunner.normalize_results(single_graph_data_results)
      expect(normalized).to eq({
        status: Rearview::Job::Status::SUCCESS,
        output: "single_graph_data_results_output",
        graph_data: {
          "stats_counts.cupcake.web_traffic.impression"=>[[1368635510, 49.0], [1368635520, 53.0], [1368635530, 62.0], [1368635540, 63.0], [1368635550, 63.0], [1368635560, 60.0], [1368635570, 0.0], [1368635580, nil]]
        }
      })
    end
    it 'normalizes monitor output with empty graph data results' do
      normalized = Rearview::MonitorRunner.normalize_results(empty_graph_data_results)
      expect(normalized).to eq({
        status: Rearview::Job::Status::SUCCESS,
        output: "empty_graph_data_results_output",
        graph_data: nil
      })
    end
    it 'normalizes monitor output with nil graph data results' do
      normalized = Rearview::MonitorRunner.normalize_results(nil_graph_data_results)
      expect(normalized).to eq({
        status: Rearview::Job::Status::SUCCESS,
        output: "nil_graph_data_results_output",
        graph_data: nil
      })
    end
    it 'normalizes nil input' do
      normalized = Rearview::MonitorRunner.normalize_results(nil)
      expect(normalized).to eq({
        status: Rearview::Job::Status::ERROR,
        output: nil,
        graph_data: nil
      })
    end
    it 'normalizes on output' do
      normalized = Rearview::MonitorRunner.normalize_results({ :output => { :status=>"error", :output=>"error message" } })
      expect(normalized).to eq({
        status: Rearview::Job::Status::ERROR,
        output: "error message",
        graph_data: nil
      })
    end
    it 'normalizes on nil output' do
      normalized = Rearview::MonitorRunner.normalize_results({ :output => nil })
      expect(normalized).to eq({
        status: Rearview::Job::Status::ERROR,
        output: nil,
        graph_data: nil
      })
    end
  end

end
