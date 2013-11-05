require 'spec_helper'

describe Rearview::Alerts::PagerDutyAlert do
  let(:job) { create(:job,:alert_keys=>["pagerduty:54232f6f4c4447efb6d15e20dbb7349b"]) }
  let(:result) {
    { :output=>
      {
        :status=>"error",
        :output=>{:status=>"error", :output=>"initialize: name or service not known", :graph_data=>nil},
        :message=>"initialize: name or service not known", :data=>nil
      }
    }
  }
  context 'alert' do
    let (:pager_alert) { Rearview::Alerts::PagerDutyAlert.new }

    before(:each) do
      HTTParty.expects(:post).once
    end

    it 'sends pager alerts' do
      pager_alert.alert(job,result)
    end

  end

  context "params" do
    context "valid uri scheme" do
      let (:result_params) { Rearview::Alerts::PagerDutyAlert.params("pagerduty:1234") }

      it "returns params" do
        result_params["scheme"].should eq("pagerduty")
        result_params["token"].should eq("1234")
      end
    end

    context "invalid uri" do
      let (:result_params) { Rearview::Alerts::PagerDutyAlert.params("foo://") }

      it "returns empty hash" do
        result_params.should eq({})
      end
    end
  end

  context 'key?' do
    context "valid params" do
      let (:params) { { "scheme" => "pagerduty", "token" => "54232f6f4c4447efb6d15e20dbb7349b" } }

      it "returns true" do
        Rearview::Alerts::PagerDutyAlert.key?(params).should be_true
      end
    end

    context "invalid scheme" do
      let (:params) { { "scheme" => "email", "token" => "54232f6f4c4447efb6d15e20dbb7349b" } }

      it "returns true" do
        Rearview::Alerts::PagerDutyAlert.key?(params).should be_false
      end
    end

    context "invalid token" do
      let (:params) { { "scheme" => "email" } }

      it "returns false" do
        Rearview::Alerts::PagerDutyAlert.key?(params).should be_false
        Rearview::Alerts::PagerDutyAlert.key?(params.merge("token" => nil)).should be_false
        Rearview::Alerts::PagerDutyAlert.key?(params.merge("token" => "")).should be_false
        Rearview::Alerts::PagerDutyAlert.key?(params.merge("token" => "_N0_")).should be_false
        Rearview::Alerts::PagerDutyAlert.key?(params.merge("token" => "foo@hungrymachinecom")).should be_false
      end
    end
  end
end
