require 'spec_helper'

describe Rearview::UrlHelper do
  let(:job) { stub(app_id: 1234, id: 42) }
  subject { Rearview::UrlHelper }
  context ".rearview_uri" do
    it "returns rearview uri" do
      subject.job_url(job).should eq("http://#{Rearview.config.default_url_options[:host]}:#{Rearview.config.default_url_options[:port]}/rearview/#dash/1234/expand/42")
    end
  end
end

