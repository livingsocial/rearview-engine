require 'spec_helper'

describe "rearview/monitor/create" do
  let(:monitor_output) {
    {:status=>"success",
     :output=>"",
     :graph_data=>
     {"deploys.deals"=>
      [[1393956250, 0.0],
       [1393956260, 0.0],
       [1393956270, 0.0],
       [1393956280, 0.0],
       [1393956290, 0.0],
       [1393956300, 0.0]]}}
  }
  let(:monitor_keys) {
    ["status",
     "output",
     "errors",
     "graph_data"]
  }
  it "renders monitor json" do
    assign(:monitor_output,monitor_output)
    render :template => "rearview/monitor/create", :formats => :json, :handler => :jbuilder
    json = JSON.parse(rendered)
    expect(json).to be_a_kind_of(Hash)
    monitor_keys.each { |k| expect(json).to include(k) }
    expect(json.keys.size).to eq(monitor_keys.size)
  end
end

