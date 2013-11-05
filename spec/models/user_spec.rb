require 'spec_helper'

describe Rearview::User do
  describe 'factory' do
    it 'should be valid' do
      expect { FactoryGirl.create(:user) }.not_to raise_error
      expect( FactoryGirl.create(:user).valid? ).to be_true
    end
  end
  describe 'validations' do
    # let!(:first_user) { FactoryGirl.build(:user) }
    # pending { should validate_presence_of(:email) }
    # pending { should validate_uniqueness_of(:email) }
    # pending { should_not allow_value("this is not an email address").for(:email) }
    # pending("requires a hungrymachine.com email address") { should_not allow_value("user@example.com").for(:email) }
    # pending { should allow_value("example@hungrymachine.com").for(:email) }
  end
end
