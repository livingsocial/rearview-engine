require 'spec_helper'

describe Rearview::MonitorController do

  before do
    sign_in_as create(:user)
    @routes = Rearview::Engine.routes
  end

  context "POST /monitor" do
    it "renders the create view" do
      Rearview::MetricsValidator.any_instance.stubs(:metric_valid?).returns(true)
      json = JsonFactory::Monitor.create
      Rearview::MonitorRunner.expects(:run).with(json["metrics"],json["monitorExpr"],json["minutes"].to_s,{},false,json["toDate"],true).once
      post :create, json
      expect(response).to render_template("rearview/monitor/create")
    end
    context "invalid metrics" do
      it "provides an error message when no metrics are provided" do
        json = JsonFactory::Monitor.create
        json["metrics"] = []
        Rearview::MonitorRunner.expects(:run).never
        Rearview::MetricsValidator.expects(:metric_valid?).never
        post :create, json
        expect(assigns(:errors)).to include("No metrics were provided")
        expect(response).to render_template("rearview/monitor/create")
      end
      it "provides an error message when metrics are invalid" do
        json = JsonFactory::Monitor.create
        Rearview::MonitorRunner.expects(:run).never
        Rearview::MetricsValidator.any_instance.stubs(:metric_valid?).returns(false)
        post :create, json
        expect(assigns(:errors)).to include("Metrics contains an invalid metric: #{json["metrics"].first}")
        expect(response).to render_template("rearview/monitor/create")
      end
    end
  end

end
