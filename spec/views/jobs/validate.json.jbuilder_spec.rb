require 'spec_helper'

describe "rearview/jobs/validate" do
  let(:job) {
    create(:job)
  }
  context "no validation errors" do
    it "renders validate json with no errors" do
      assign(:job,job)
      assign(:validation_fields,{})
      render :template => "rearview/jobs/validate", :formats => :json, :handler => :jbuilder
      json = JSON.parse(rendered)
      expect(json).to be_a_kind_of(Hash)
      expect(json["errors"]).to be_empty 
    end
  end
  context "validation errors" do
    it "renders validate json with field errors" do
      job.name = nil
      job.valid?
      assign(:job,job)
      assign(:validation_fields,{"name" => nil})
      render :template => "rearview/jobs/validate", :formats => :json, :handler => :jbuilder
      json = JSON.parse(rendered)
      expect(json).to be_a_kind_of(Hash)
      expect(json["errors"]).not_to be_empty 
      expect(json["errors"]["name"]).not_to be_empty 
    end
  end
end

