require 'spec_helper'

describe Rearview::JobData do
  describe 'factory' do
    it 'should be valid' do
      expect { FactoryGirl.create(:job_data) }.not_to raise_error
      expect( FactoryGirl.create(:job_data).valid? ).to be_true
    end
  end
  describe 'validations' do
    it { should validate_presence_of(:job_id) }
    it { should validate_presence_of(:data) }
  end
end
