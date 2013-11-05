require 'spec_helper'

describe "rearview/jobs/errors" do
  let(:job_errors) {
    [ create(:job_error), create(:job_error) ]
  }
  let(:job_errors_keys) {
    ["id",
     "jobId",
     "status",
     "message",
     "endDate",
     "date"]
  }
  it "renders jobs errors json" do
    assign(:job_errors,job_errors)
    render :template => "rearview/jobs/errors", :formats => :json, :handler => :jbuilder
    json = JSON.parse(rendered)
    expect(json).to be_a_kind_of(Array)
    expect(json.size).to eq(2)
    job_errors_keys.each { |k| expect(json[0]).to include(k) }
    expect(json[0].keys.size).to eq(job_errors_keys.size)
  end
  context "renders json with the correct enclosing type when there is no data" do
    it "when nil" do
      assign(:job_errors,nil)
      render :template => "rearview/jobs/errors", :formats => :json, :handler => :jbuilder
      json = JSON.parse(rendered)
      expect(json).to be_a_kind_of(Array)
      expect(json).to be_empty
    end
    it "when empty" do
      assign(:job_errors,[])
      render :template => "rearview/jobs/errors", :formats => :json, :handler => :jbuilder
      json = JSON.parse(rendered)
      expect(json).to be_a_kind_of(Array)
      expect(json).to be_empty
    end
  end
end

