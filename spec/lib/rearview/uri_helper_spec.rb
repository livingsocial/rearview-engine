require 'spec_helper'

describe Rearview::UriHelper do
  let(:job) { stub(app_id: 1234, id: 42) }
  subject { Rearview::UriHelper }

  context ".rearview_uri" do
    it "returns rearview uri" do
      subject.rearview_uri(job).should eq("https://rearview.livingsocial.net/#dash/1234/expand/42")
    end
  end
end
