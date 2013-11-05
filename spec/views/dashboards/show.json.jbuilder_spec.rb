require 'spec_helper'

describe "rearview/dashboards/show" do
  let(:dashboard) {
    create(:dashboard)
  }
  let(:dashboard_keys) {
    ["id",
     "userId",
     "name",
     "createdAt",
     "modifiedAt",
     "description",
     "children"]
  }
  it "renders dashboard json" do
    assign(:dashboard,dashboard)
    render :template => "rearview/dashboards/show", :formats => :json, :handler => :jbuilder
    json = JSON.parse(rendered)
    expect(json).to be_a_kind_of(Hash)
    dashboard_keys.each { |k| expect(json).to include(k) }
    expect(json.keys.size).to eq(dashboard_keys.size)
  end
end

