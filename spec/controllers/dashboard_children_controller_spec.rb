require 'spec_helper'

describe Rearview::DashboardChildrenController do

  let(:parent) { create(:dashboard) }
  before do
    @routes = Rearview::Engine.routes
    sign_in_as create(:user)
  end

  context "GET /children" do
    it "renders the dashboards index view" do
      get :index, dashboard_id: parent.id, format: :json
      expect(response).to render_template("rearview/dashboards/index")
    end
  end

  context "POST /children" do
    it "renders the dashboards show view" do
      json = JsonFactory::Dashboard.create(build(:dashboard))
      json[:dashboard_id] = parent.id
      post :create, json
      expect(response).to render_template("rearview/dashboards/show")
    end
    it "creates the child association to the parent" do
      dashboard = build(:dashboard)
      json = JsonFactory::Dashboard.create(build(:dashboard))
      json[:dashboard_id] = parent.id
      Rearview::Dashboard.stubs(:new).returns(dashboard)
      dashboard.expects(:parent=).with(parent)
      post :create, json
    end
  end

end
