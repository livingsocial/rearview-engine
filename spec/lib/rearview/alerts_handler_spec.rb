require 'spec_helper'

describe Rearview::AlertsHandler do
  let(:job) { create(:job,:alert_keys=>["mailto:foo@foo.com","pagerduty:387214d0a12c012fbf5a22000afc49b8"]) }
  let(:email_alert) { mock }
  let(:pager_alert) { mock }
  let(:error_results) {
    {:output=>
      {
        :status=>"error",
        :output=>{:status=>"error", :output=>"initialize: name or service not known", :graph_data=>nil},
        :message=>"initialize: name or service not known", :data=>nil
      }
    }
  }
  context 'run' do
    before do
      Rearview::Alerts::EmailAlert.stubs(:new).returns(email_alert)
      Rearview::Alerts::PagerDutyAlert.stubs(:new).returns(pager_alert)
    end
    it 'should not send alerts if they are disabled' do
      Rearview.config.stubs(:alerts_enabled?).returns(false)
      alerts_handler = Rearview::AlertsHandler.new(job,error_results)
      email_alert.expects(:alert).never
      alerts_handler.run
    end
    it 'should keep sending alerts even if an alert client fails' do
      alerts_handler = Rearview::AlertsHandler.new(job,error_results)
      email_alert.stubs(:alert).raises(StandardError,"oops")
      pager_alert.stubs(:alert).raises(StandardError,"oops")
      expect{ alerts_handler.run }.not_to raise_error
    end
    it 'returns itself' do
      alerts_handler = Rearview::AlertsHandler.new(job,error_results)
      email_alert.expects(:alert).once
      pager_alert.stubs(:alert).raises(StandardError,"unexpected")
      expect(alerts_handler.run).to eq(alerts_handler)
    end
  end

end


