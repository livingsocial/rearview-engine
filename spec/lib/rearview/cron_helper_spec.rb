require 'spec_helper'

describe Rearview::CronHelper do

  context "next_valid_time_after" do
    before do
      now = Time.now
      Timecop.freeze(Time.local(now.year,now.mon,now.day))
    end

    after do
      Timecop.return
    end

    it "should calculate the correct delay for '0 * * * * ?'" do
      cron_expr = "0 * * * * ?"
      expect( Rearview::CronHelper.next_valid_time_after(cron_expr) ).to eq(60.0)
    end

    it "should calculate the correct delay for '0 30 * * * ?'" do
      cron_expr = "0 30 * * * ?"
      expect( Rearview::CronHelper.next_valid_time_after(cron_expr) ).to eq( 30 * 60 )
    end

    it "should calculate the correct delay for '0 0 13 * * ?'" do
      cron_expr = "0 0 13 * * ?"
      expect( Rearview::CronHelper.next_valid_time_after(cron_expr) ).to eq( 13 * 60 * 60 )
    end

  end

  context "valid_expression?" do
    it "should reject invalid expressions" do
      expect(Rearview::CronHelper.valid_expression?("nope")).to be_false
    end
    it "should accept valid expressions" do
      expect(Rearview::CronHelper.valid_expression?("0 * * * * ?")).to be_true
    end
  end

end

