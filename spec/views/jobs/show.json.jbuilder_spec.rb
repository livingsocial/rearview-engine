require 'spec_helper'

describe "rearview/jobs/show" do
  let(:job) {
    create(:job)
  }
  let(:job_keys) {
    ["id",
     "userId",
     "dashboardId",
     "name",
     "cronExpr",
     "metrics",
     "monitorExpr",
     "minutes",
     "toDate",
     "description",
     "active",
     "status",
     "lastRun",
     "alertKeys",
     "errorTimeout",
     "createdAt",
     "modifiedAt",
     "errors"]
  }
  it "renders job json" do
    assign(:job,job)
    render :template => "rearview/jobs/show", :formats => :json, :handler => :jbuilder
    json = JSON.parse(rendered)
    job_keys.each { |k| expect(json).to include(k) }
    expect(json.keys.size).to eq(job_keys.size)
  end
end

