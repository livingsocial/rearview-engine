require 'spec_helper'

describe Rearview::ApplicationHelper do
  context '#rearview_static_path' do
    context 'development' do
      it 'returns the non-compiled path' do
        Rails.env.stubs(:development?).returns(true)
        expect(helper.rearview_static_path).to eq('/rearview-src')
      end
    end
    context 'non-development' do
      it 'returns the compiled path' do
        Rails.env.stubs(:development?).returns(false)
        expect(helper.rearview_static_path).to eq('/rearview')
      end
    end
    context 'segment' do
      it 'prepends if present' do
        expect(helper.rearview_static_path('/foo')).to eq('/rearview/foo')
      end
    end
  end
  context '#rearview_link_tag' do
    it 'creates a link tag prepended with rearview_static_path' do
      expect(helper.rearview_link_tag('/foo/bar.css')).to eq(%q{<link href="/rearview/foo/bar.css" />})
    end
  end
  context '#rearview_img_tag' do
    it 'creates a img tag prepended with rearview_static_path and img' do
      expect(helper.rearview_img_tag('/foo/bar.gif')).to eq(%q{<img src="/rearview/img/foo/bar.gif" />})
    end
  end
end
