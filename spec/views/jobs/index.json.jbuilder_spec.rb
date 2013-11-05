require 'spec_helper'

describe "rearview/jobs/index" do
  let(:jobs) {
    [ create(:job), create(:job) ]
  }
  it "renders jobs json" do
    assign(:jobs,jobs)
    render :template => "rearview/jobs/index", :formats => :json, :handler => :jbuilder
    json = JSON.parse(rendered)
    expect(json).to be_a_kind_of(Array)
    expect(json.size).to eq(2)
  end
  context "renders json with the correct enclosing type when there is no data" do
    it "when nil" do
      assign(:jobs,nil)
      render :template => "rearview/jobs/index", :formats => :json, :handler => :jbuilder
      json = JSON.parse(rendered)
      expect(json).to be_a_kind_of(Array)
      expect(json).to be_empty
    end
    it "when empty" do
      assign(:jobs,[])
      render :template => "rearview/jobs/index", :formats => :json, :handler => :jbuilder
      json = JSON.parse(rendered)
      expect(json).to be_a_kind_of(Array)
      expect(json).to be_empty
    end
  end
end

