require 'spec_helper'

describe Rearview::Alerts::EmailAlert do
  let(:job) { create(:job) }
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
    let (:email_alert) { Rearview::Alerts::EmailAlert.new }
    let (:action_mailer) { mock }

    before do
      action_mailer.expects(:deliver)
    end

    it 'sends email alerts' do
      Rearview::AlertMailer.expects(:alert_email).with("foo@hungrymachine.com", job, result).returns(action_mailer)
      email_alert.alert(job, result)
    end

    it "sends email alerts with uri" do
      Rearview::AlertMailer.expects(:alert_email).with("foo@hungrymachine.com", job, result).returns(action_mailer)
      email_alert.alert(job, result)
    end
  end

  context "params" do
    context "valid uri scheme" do
      let (:params) { Rearview::Alerts::EmailAlert.params("mailto:foo@bar.com") }

      it "returns params" do
        params["scheme"].should eq("mailto")
        params["email"].should eq("foo@bar.com")
      end

      context "invalid uri" do
        let (:result_params) { Rearview::Alerts::EmailAlert.params("campfires://") }

        it "returns empty hash" do
          result_params.should eq({})
        end
      end
    end
  end

  context 'key?' do
    context "valid params" do
      let (:params) { { "scheme" => "mailto" } }

      it "returns true" do
        Rearview::Alerts::EmailAlert.key?(params.merge("email" => "foo@bar.com")).should be_true
        Rearview::Alerts::EmailAlert.key?(params.merge("email" => "foo+alerts@bar.com")).should be_true
      end
    end

    context "invalid scheme" do
      let (:params) { { "scheme" => "email", "email" => "1234" } }

      it "returns true" do
        Rearview::Alerts::EmailAlert.key?(params).should be_false
      end
    end

    context "missing email" do
      let (:params) { { "scheme" => "hungry" } }

      it "returns false" do
        Rearview::Alerts::EmailAlert.key?(params).should be_false
      end
    end

    context "invalid email" do
      let (:params) { { "scheme" => "mailto" } }

      it "returns false" do
        Rearview::Alerts::EmailAlert.key?(params.merge("email" => nil)).should be_false
        Rearview::Alerts::EmailAlert.key?(params.merge("email" => "")).should be_false
        Rearview::Alerts::EmailAlert.key?(params.merge("email" => "_N0_")).should be_false
      end
    end
  end
end
