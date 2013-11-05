require 'spec_helper'

describe Rearview::Dashboard do
  describe 'factory' do
    it 'should be valid' do
      expect { FactoryGirl.create(:dashboard) }.not_to raise_error
      expect( FactoryGirl.create(:dashboard).valid? ).to be_true
    end
  end
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:user_id) }
  end
end
