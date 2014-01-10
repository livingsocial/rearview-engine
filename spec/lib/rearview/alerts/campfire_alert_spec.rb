require 'spec_helper'

describe Rearview::Alerts::CampfireAlert do
  let(:result) { stub }
  let(:campfire_alert) { Rearview::Alerts::CampfireAlert.new }

  context "alert" do
    context "valid key" do
      let(:job) { FactoryGirl.create(:job, alert_keys: ["campfire://mycompany.com?token=abc&room=myroom"]) }

      context "with provided error message" do
        let(:result) { { message: "alert alert!"} }

        it "notifies campfire" do
          Broach.expects(:speak).with("myroom", "alert alert! #{Rearview::UrlHelper.job_url(job)}")
          campfire_alert.alert(job, result)
        end
      end

      context "without provided error message" do
        let(:result) { { } }

        it "notifies campfire" do
          Broach.expects(:speak).with("myroom", "Job did not provide an error description #{Rearview::UrlHelper.job_url(job)}")
          campfire_alert.alert(job, result)
        end
      end
    end

    context "invalid key" do
      let(:job) { stub(alert_keys: ["campfire://foo"], app_id: 42, id: 1234) }

      it "skips notification" do
        Rearview::Alerts::CampfireAlert.expects(:key?).returns(false)
        Broach.expects(:speak).with("nyan", "").never
        campfire_alert.alert(job, result)
      end
    end
  end

  context "params" do
    context "valid uri" do
      let (:result_params) { Rearview::Alerts::CampfireAlert.params("campfire://hungrymachine?token=1234&room=nyan") }

      it "returns params" do
        result_params["scheme"].should eq("campfire")
        result_params["account"].should eq("hungrymachine")
        result_params["token"].should eq("1234")
        result_params["room"].should eq("nyan")
        result_params["use_ssl"].should be_true
      end
    end

    context "invalid uri" do
      let (:result_params) { Rearview::Alerts::CampfireAlert.params("campfires://") }

      it "returns empty hash" do
        result_params.should eq({})
      end
    end
  end

  context 'key?' do
    context "valid params" do
      let (:params) { { "scheme" => "campfire", "token" => "1234", "room" => "nyan" } }

      it "returns true" do
        Rearview::Alerts::CampfireAlert.key?(params).should be_true
      end
    end

    context "invalid scheme" do
      let (:params) { { "scheme" => "email", "room" => "nyan" } }

      it "returns true" do
        Rearview::Alerts::CampfireAlert.key?(params).should be_false
      end
    end

    context "missing token" do
      let (:params) { { "scheme" => "hungry", "room" => "nyan" } }

      it "returns false" do
        Rearview::Alerts::CampfireAlert.key?(params).should be_false
      end
    end

    context "missing room" do
      let (:params) { { "scheme" => "hungry", "token" => "123" } }

      it "returns false" do
        Rearview::Alerts::CampfireAlert.key?(params).should be_false
      end
    end
  end
end
