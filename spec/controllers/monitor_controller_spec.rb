require 'spec_helper'

describe Rearview::MonitorController do

  before do
    sign_in_as create(:user)
    @routes = Rearview::Engine.routes
  end

  context "POST /monitor" do
    it "renders the create view" do
      json = JsonFactory::Monitor.create
      Rearview::MonitorRunner.expects(:run).with(json["metrics"],json["monitorExpr"],json["minutes"].to_s,{},false,json["toDate"],true).once
      post :create, json
      render_template(:create)
    end
  end

end
