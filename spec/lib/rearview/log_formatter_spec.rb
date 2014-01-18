require 'spec_helper'

describe Rearview::LogFormatter do
  let(:formatter) { Rearview::LogFormatter.new }
  context '#call' do
    it "includes the thread name" do
      expect(formatter.call("DEBUG",Time.now.utc,"Rearview","yo")).to match(/#\d+\/main]/)
    end
    it "includes Rearview as the progname if none is provided" do
      expect(formatter.call("DEBUG",Time.now.utc,nil,"yo")).to match(/Rearview: yo$/)
    end
  end
end
