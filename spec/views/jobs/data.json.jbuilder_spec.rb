require 'spec_helper'

describe "rearview/jobs/data" do
  let(:job_data) { create(:job_data) }
  let(:job_data_keys) {
    ["status",
     "output",
     "graph_data"]
  }
  it "render json" do
    assign(:job_data,create(:job_data))
    render :template => "rearview/jobs/data", :formats => :json, :handler => :jbuilder
    json = JSON.parse(rendered)
    expect(json).to be_a_kind_of(Hash)
    job_data_keys.each { |k| expect(json).to include(k) }
    expect(json.keys.size).to eq(job_data_keys.size)
    expect(json["graph_data"]).to be_a_kind_of(Hash)
  end
  it "render json with the correct enclosing type when there is no data" do
    assign(:job_data,nil)
    render :template => "rearview/jobs/data", :formats => :json, :handler => :jbuilder
    json = JSON.parse(rendered)
    expect(json).to be_a_kind_of(Hash)
    expect(json).to be_empty
  end
end

