require 'spec_helper'

RSpec::Matchers.define :be_parsed do |expected|

  match do |actual|
    !actual.error?
  end

  failure_message_for_should do |actual|
    "expected that #{actual.data} would be parseable (#{actual.error})"
  end

  failure_message_for_should_not do |actual|
    "expected that #{actual.data} would not be parseable"
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
    context 'is parseable' do
      it 'for all values in metrics.yml' do
        metrics = YAML.load_file("spec/data/metrics.yml")
        parser = Graphite::TargetParser.new
        metrics.each do |m|
          parser.parse(m)
          expect(parser).to be_parsed
        end
      end
    end
  end

  context 'string' do
    context 'is valid' do
      it 'with single quoted strings' do
        p =  Graphite::TargetParser.parse(%q[alias(summarize(stats_counts.message_center.consumer_replies.created, '12h'), 'Consumer replies')])
        expect(p).to be_parsed
      end
      it 'with double quoted strings' do
        p =  Graphite::TargetParser.parse(%q[alias(summarize(stats_counts.message_center.consumer_replies.created, "12h"), "Consumer replies")])
        expect(p).to be_parsed
      end
    end
  end

  context 'path' do
    context 'is valid' do
      it 'with seg1' do
        p =  Graphite::TargetParser.parse("seg1")
        expect(p).to be_parsed
      end
      it 'with seg1.*' do
        p =  Graphite::TargetParser.parse("seg1.*")
        expect(p).to be_parsed
      end
      it 'with seg1.seg2' do
        p =  Graphite::TargetParser.parse("seg1.seg2")
        expect(p).to be_parsed
      end
      it 'with seg1_seg2' do
        p =  Graphite::TargetParser.parse("seg1_seg2")
        expect(p).to be_parsed
      end
      it 'with seg1_seg2.seg3' do
        p =  Graphite::TargetParser.parse("seg1_seg2.seg3")
        expect(p).to be_parsed
      end
      it 'with *.seg3' do
        p =  Graphite::TargetParser.parse("*.seg3")
        expect(p).to be_parsed
      end
      it 'with *' do
        p =  Graphite::TargetParser.parse("*")
        expect(p).to be_parsed
      end
    end
  end

end

