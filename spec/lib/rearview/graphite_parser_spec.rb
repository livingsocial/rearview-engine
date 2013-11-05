require 'spec_helper'

describe Rearview::GraphiteParser do

  artifact   = open("spec/data/test.dat").read
  nanPayload = open("spec/data/nan.dat").read

  describe 'GraphiteParser' do
    it "handles graphite data" do
      data = Rearview::GraphiteParser.parse(artifact)
      data.length.should == 3
    end

    it "handles NaN in graphite data" do
      data = Rearview::GraphiteParser.parse(nanPayload)
      data.length.should === 3
    end

    it "handles no data" do
      data = Rearview::GraphiteParser.parse("")
      data.length.should === 0
    end
  end
end
