require 'spec_helper'

describe Rearview::DashboardsController do

  before do
    sign_in_as create(:user)
    @routes = Rearview::Engine.routes
  end

  context "GET /dashboards" do
    it "renders the index view" do
      get :index, format: :json
      expect(response).to render_template("rearview/dashboards/index")
    end
  end

  context "GET /dashboards/:id" do
    it "renders the show view" do
      app = create(:dashboard)
      get :show, id: app.id, format: :json
      expect(response).to render_template("rearview/dashboards/show")
    end
  end

  context "GET /dashboards/:id/errors" do
    it "renders the errors view" do
      app = create(:dashboard)
      get :errors, id: app.id, format: :json
      expect(response).to render_template("rearview/dashboards/errors")
    end
  end

  context "POST /dashboards" do
    it "renders the create view" do
      app = build(:dashboard)
      post :create, JsonFactory::Dashboard.create(app)
      expect(response).to render_template("rearview/dashboards/show")
    end
  end

  context "PUT /dashboards/:id" do
    it "renders the update view" do
      app1 = create(:dashboard)
      app2 = build(:dashboard)
      params = JsonFactory::Dashboard.create(app2) do |json|
        json["id"]=app1.id
        json["userId"]=app1.user_id
      end
      put :update, params
      expect(response).to render_template("rearview/dashboards/show")
    end
  end

  context "DELETE /dashboards/:id" do
    it "renders the show view" do
      app = create(:dashboard)
      delete :destroy, id: app.id, format: :json
      expect(response).to render_template("rearview/dashboards/show")
    end
  end

end
