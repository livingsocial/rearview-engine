require 'spec_helper'

RSpec::Matchers.define :be_parsed do |expected|
  match do |actual|
    !actual.nil?
  end

  failure_message_for_should do |actual|
    "expected that #{actual} would be parseable"
  end

  failure_message_for_should_not do |actual|
    "expected that #{actual} would not be parseable"
  end

  description do
    "be parseable"
  end
end

describe Graphite::TargetParser do

  context '.error?' do
    let(:invalid_target) { %q[alias@(stats.x.y,"processed")] }
    let(:valid_target) { %q[alias(stats.x.y,"processed")] }
    it 'should be true if there is an error' do
       p = Graphite::TargetParser.parse(invalid_target)
       expect(p.error?).to be_true
    end
    it 'should be false if there is no error' do
       p = Graphite::TargetParser.parse(valid_target)
       expect(p.error?).to be_false
    end
  end

  context '.error' do
    let(:invalid_target) { %q[alias@(stats.x.y,"processed")] }
    it 'should return the parsing failure message, line, and column' do
       p = Graphite::TargetParser.parse(invalid_target)
       expect(p.error[:message].present?).to be_true
       expect(p.error[:line].present?).to be_true
       expect(p.error[:column].present?).to be_true
    end
  end

  context '.grammer' do
    it 'should return a valid grammer file' do
      grammer = Graphite::TargetParser.grammer
      expect(grammer).not_to be_nil
      expect(File.exists?(grammer)).to be_true
    end
  end

  context '.parse!' do
    let(:invalid_target) { %q[alias@(stats.x.y,"processed")] }
    it 'should raise a typed exception when the text is unparseable' do
       p = Graphite::TargetParser.new
       expect { p.parse!(invalid_target) }.to raise_error(Graphite::TargetParser::TargetParserError)
    end
  end

  context 'expression' do
    context 'is valid' do
      examples = {
        simple_method: %q[alias(stats.x.y,"processed")],
        nested_method: %q[color(alias(stats.x.y,"processed"),"red")],
        complex_method1: %q[alias(color(summarize(sumSeries(stats_counts.mailpoller.hungrymail_poller.432299*.delivery_worker.messages),"1min"),"orange"),"processed")],
        complex_method2: %q[color(alias(nonNegativeDerivative(sumSeries(keepLastValue(livingsocial.mailing.mta.b*.summary.messages_delivered))), "today"), "blue")],
        complex_method3: %q[color(alias(summarize(stats_counts.mail.messages.queued, "1min"), "queued"),"green")],
        complex_method4: %q[color(alias(dashed(summarize(stats_counts.mail.mta-scripts.mail_sends_created,"1min"),2.5),"mail sends"),"blue")],
        complex_method5: %q[alias(secondYAxis(dashed(drawAsInfinite(deploys.mailpoller), 2.5)), "mailpoller deploys")],
        complex_method6: %q[alias(secondYAxis(dashed(drawAsInfinite(deploys.hungrymailer),2.5)), "hungrymailer deploys")],
        complex_method7: %q[alias(color(secondYAxis(livingsocial.mailing.hmail.mailbox_unsent),"red"),"unsent mailbox")]
      }
      it 'with simple method: '+examples[:simple_method] do
        p = Graphite::TargetParser.parse(examples[:simple_method])
        expect(p.tree).to be_parsed
      end
      it 'with nested method: '+examples[:nested_method] do
        p = Graphite::TargetParser.parse(examples[:nested_method])
        expect(p.tree).to be_parsed
      end
      it 'with complex method ex1: '+examples[:complex_method1] do
        p = Graphite::TargetParser.parse(examples[:complex_method1])
        expect(p.tree).to be_parsed
      end
      it 'with complex method ex2: '+examples[:complex_method2] do
        p = Graphite::TargetParser.parse(examples[:complex_method2])
        expect(p.tree).to be_parsed
      end
      it 'with complex method ex3: '+examples[:complex_method3] do
        p = Graphite::TargetParser.parse(examples[:complex_method3])
        expect(p.tree).to be_parsed
      end
      it 'with complex method ex4: '+examples[:complex_method4] do
        p = Graphite::TargetParser.parse(examples[:complex_method4])
        expect(p.tree).to be_parsed
      end
      it 'with complex method ex5: '+examples[:complex_method5] do
        p = Graphite::TargetParser.parse(examples[:complex_method5])
        expect(p.tree).to be_parsed
      end
      it 'with complex method ex6: '+examples[:complex_method6] do
        p = Graphite::TargetParser.parse(examples[:complex_method6])
        expect(p.tree).to be_parsed
      end
      it 'with complex method ex7: '+examples[:complex_method7] do
        p = Graphite::TargetParser.parse(examples[:complex_method7])
        expect(p.tree).to be_parsed
      end
    end
  end

  context 'path' do
    context 'is valid' do
      it 'with seg1' do
        p =  Graphite::TargetParser.parse("seg1")
        expect(p.tree).to be_parsed
      end
      it 'with seg1.*' do
        p =  Graphite::TargetParser.parse("seg1.*")
        expect(p.tree).to be_parsed
      end
      it 'with seg1.seg2' do
        p =  Graphite::TargetParser.parse("seg1.seg2")
        expect(p.tree).to be_parsed
      end
      it 'with seg1_seg2' do
        p =  Graphite::TargetParser.parse("seg1_seg2")
        expect(p.tree).to be_parsed
      end
      it 'with seg1_seg2.seg3' do
        p =  Graphite::TargetParser.parse("seg1_seg2.seg3")
        expect(p.tree).to be_parsed
      end
    end
    context 'is invalid' do
      it 'with *' do
        p =  Graphite::TargetParser.parse("*")
        expect(p.tree).not_to be_parsed
      end
    end
  end

end

