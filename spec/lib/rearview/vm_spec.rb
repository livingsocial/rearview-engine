require 'spec_helper'

describe Rearview::Vm do

  let(:vm) { Rearview::Vm.new }

  context '#heap' do
    it "should be present" do
      expect(vm.heap.present?).to be_true
    end
  end

  context '#non_heap' do
    it "should be present" do
      expect(vm.non_heap.present?).to be_true
    end
  end

  context '#total_memory' do
    it "should be non-zero" do
      expect(vm.total_memory>0).to be_true
    end
  end

  context '#free_memory' do
    it "should be non-zero" do
      expect(vm.free_memory>0).to be_true
    end
  end

  context '#max_memory' do
    it "should be non-zero" do
      expect(vm.max_memory>0).to be_true
    end
  end

  describe Rearview::Vm::Memory do
    let(:heap) { Rearview::Vm::Heap.new }
    let(:non_heap) { Rearview::Vm::Heap.new }

    context '#committed' do
      it "heap should be non-zero" do
        expect(heap.committed>0).to be_true
      end
      it "non_heap should be non-zero" do
        expect(non_heap.committed>0).to be_true
      end
    end

    context '#init' do
      it "heap should be non-zero" do
        expect(heap.init>0).to be_true
      end
      it "non_heap should be non-zero" do
        expect(non_heap.init>0).to be_true
      end
    end

    context '#max' do
      it "heap should be non-zero" do
        expect(heap.max>0).to be_true
      end
      it "non_heap should be non-zero" do
        expect(non_heap.max>0).to be_true
      end
    end

    context '#used' do
      it "heap should be non-zero" do
        expect(heap.used>0).to be_true
      end
      it "non_heap should be non-zero" do
        expect(non_heap.used>0).to be_true
      end
    end

  end

end
