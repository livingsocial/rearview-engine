require 'spec_helper'

describe Graphite::TargetGrammer do

  example_targets = {
    simple_method: %q[alias(stats.x.y,"processed")],
    nested_method: %q[color(alias(stats.x.y,"processed"),"red")],
    color_only: %q[color(stats.x.y,"blue")],
    very_nested: %q[alias(color(summarize(sumSeries(stats.*.y),"1min"),"orange"),"processed")]
  }

  describe Graphite::TargetGrammer::Target do
    context '#expressions' do
      it 'should contain all the expressions' do
        p = Graphite::TargetParser.parse(example_targets[:nested_method])
        expect(p.tree.expressions.count).to eq(2)
      end
      it 'should be empty if there are no expressions' do
        p = Graphite::TargetParser.parse("seg1_seg2.seg3")
        expect(p.tree.expressions).to eq([])
      end
    end
    context '#color' do
      it 'should return the color when its present' do
        p = Graphite::TargetParser.parse(example_targets[:nested_method])
        expect(p.tree.color).to eq("red")
      end
      it 'should return nil if there is no color' do
        p = Graphite::TargetParser.parse(example_targets[:simple_method])
        expect(p.tree.color).to be_nil
        p = Graphite::TargetParser.parse("seg1_seg2.seg3")
        expect(p.tree.color).to be_nil
      end
    end
    context '#alias' do
      it 'should return the alias when its present' do
        p = Graphite::TargetParser.parse(example_targets[:nested_method])
        expect(p.tree.alias).to eq("processed")
      end
      it 'should return nil if there is no alias' do
        p = Graphite::TargetParser.parse(example_targets[:color_only])
        expect(p.tree.alias).to be_nil
        p = Graphite::TargetParser.parse("seg1_seg2.seg3")
        expect(p.tree.alias).to be_nil
      end
    end
    context '#metric' do
      it 'should return the metric for nested expressions' do
        p = Graphite::TargetParser.parse(example_targets[:nested_method])
        expect(p.tree.metric).to eq("stats.x.y")
      end
      it 'should return the metric for a path only target' do
        p = Graphite::TargetParser.parse("seg1_seg2.seg3")
        expect(p.tree.metric).to eq("seg1_seg2.seg3")
      end
      it 'should return the metric for very nested expressions' do
        p = Graphite::TargetParser.parse(example_targets[:very_nested])
        expect(p.tree.metric).to eq("stats.*.y")
      end
    end
    context '#functions' do
      it 'should return all functions when present' do
        p = Graphite::TargetParser.parse(example_targets[:nested_method])
        expect(p.tree.functions).to include("color")
        expect(p.tree.functions).to include("alias")
      end
      it 'should be empty if there are no functions' do
        p = Graphite::TargetParser.parse("seg1_seg2.seg3")
        expect(p.tree.functions).to eq([])
      end
    end
    context '#path?' do
      it 'should be true if the target is a path' do
        p = Graphite::TargetParser.parse("seg1_seg2.seg3")
        expect(p.tree.path?).to be_true
      end
      it 'should be false if the target is not a path' do
        p = Graphite::TargetParser.parse(example_targets[:nested_method])
        expect(p.tree.path?).to be_false
      end
    end
    context '#expression?' do
      it 'should be true if the target is an expression' do
        p = Graphite::TargetParser.parse(example_targets[:nested_method])
        expect(p.tree.expression?).to be_true
      end
      it 'should be false if the target is not an expression' do
        p = Graphite::TargetParser.parse("seg1_seg2.seg3")
        expect(p.tree.expression?).to be_false
      end
    end
    context '#to_model' do
      it 'should create a model from a target' do
        p = Graphite::TargetParser.parse(example_targets[:nested_method])
        model = p.tree.to_model
        expect(model.color).to eq("red")
        expect(model.alias).to eq("processed")
        expect(model.metric).to eq("stats.x.y")
        expect(model.functions).to include("color")
        expect(model.functions).to include("alias")
      end
    end
  end

end

