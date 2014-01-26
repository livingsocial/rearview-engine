require 'spec_helper'

describe Graphite::RawParser do

  artifact   = open("spec/data/test.dat").read
  nanPayload = open("spec/data/nan.dat").read

  describe '.parse' do
    it "handles graphite data" do
      data = Graphite::RawParser.parse(artifact)
      data.length.should == 3
    end

    it "handles NaN in graphite data" do
      data = Graphite::RawParser.parse(nanPayload)
      data.length.should === 3
    end

    it "handles no data" do
      data = Graphite::RawParser.parse("")
      data.length.should === 0
    end
  end

end
