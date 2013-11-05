require 'spec_helper'

describe "rearview/dashboards/index" do
  let(:dashboards) {
    [ create(:dashboard), create(:dashboard) ]
  }
  it "renders dashboards json" do
    assign(:dashboards,dashboards)
    render :template => "rearview/dashboards/index", :formats => :json, :handler => :jbuilder
    json = JSON.parse(rendered)
    expect(json).to be_a_kind_of(Array)
    expect(json.size).to eq(2)
  end
  context "renders json with the correct enclosing type when there is no data" do
    it "when nil" do
      assign(:dashboards,nil)
      render :template => "rearview/dashboards/index", :formats => :json, :handler => :jbuilder
      json = JSON.parse(rendered)
      expect(json).to be_a_kind_of(Array)
      expect(json).to be_empty
    end
    it "when empty" do
      assign(:dashboards,[])
      render :template => "rearview/dashboards/index", :formats => :json, :handler => :jbuilder
      json = JSON.parse(rendered)
      expect(json).to be_a_kind_of(Array)
      expect(json).to be_empty
    end
  end
end

