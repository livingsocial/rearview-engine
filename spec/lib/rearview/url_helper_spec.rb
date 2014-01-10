require 'spec_helper'

describe Rearview::UrlHelper do
  subject { Rearview::UrlHelper }
  context ".job_url" do
    context "job in dashboard with parent" do
      it "generates the correct url" do
        dashboard_child = FactoryGirl.create(:dashboard,parent: FactoryGirl.create(:dashboard))
        job = FactoryGirl.create(:job,app_id: dashboard_child.id)
        expected_url = "http://%s:%s/rearview/#dash/%s/expand/%s" % [
          Rearview.config.default_url_options[:host],
          Rearview.config.default_url_options[:port],
          dashboard_child.parent_id,
          job.id
        ]
        expect(subject.job_url(job)).to eq(expected_url)
      end
    end
    context "job in dashboard without parent" do
      it "generates the correct url" do
        job = FactoryGirl.create(:job)
        expected_url = "http://%s:%s/rearview/#dash/%s/expand/%s" % [
          Rearview.config.default_url_options[:host],
          Rearview.config.default_url_options[:port],
          job.app_id,
          job.id
        ]
        expect(subject.job_url(job)).to eq(expected_url)
      end
    end
  end
end

