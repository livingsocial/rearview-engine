require 'spec_helper'

describe 'Rearview::Ext::Numeric' do
  context '#bytes_to_kilobytes' do
    it "should convert bytes to kilobytes" do
      expect(1024.bytes_to_kilobytes).to eq(1)
      expect(10485760.bytes_to_kilobytes).to eq(10240)
    end
  end
  context '#bytes_to_megabytes' do
    it "should convert bytes to megabytes" do
      expect(1048576.bytes_to_megabytes).to eq(1)
      expect(10485760.bytes_to_megabytes).to eq(10)
    end
  end
end
