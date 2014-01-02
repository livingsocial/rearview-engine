require 'spec_helper'

describe Rearview::User do
  describe 'factory' do
    it 'should be valid' do
      expect { FactoryGirl.create(:user) }.not_to raise_error
      expect( FactoryGirl.create(:user).valid? ).to be_true
    end
  end
  describe 'validations' do
    let!(:first_user) { FactoryGirl.build(:user) }
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email) }
  end
  describe '.valid_google_oauth2_email?' do
    it "should not be valid unless an email is present" do
      expect(Rearview::User.valid_google_oauth2_email?(nil)).to be_false
    end
    it "should not be valid unless :matching_emails is present" do
      Rearview.config.authentication.delete(:matching_emails)
      expect(Rearview::User.valid_google_oauth2_email?("foo@foo.com")).to be_false
    end
    it "should not be valid unless it matches the :matching_emails regexp" do
      Rearview.config.authentication[:matching_emails] = /@mycompany\.com$/
      expect(Rearview::User.valid_google_oauth2_email?("foo@foo.com")).to be_false
      expect(Rearview::User.valid_google_oauth2_email?("foo@mycompany.com")).to be_true
    end
  end
end
