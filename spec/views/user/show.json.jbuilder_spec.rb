require 'spec_helper'

describe "rearview/user/show" do
  let(:user) {
    create(:user)
  }
  let(:user_keys) {
    ["id",
     "email",
     "preferences",
     "firstName",
     "lastName",
     "lastLogin",
     "createdAt",
     "modifiedAt"]
  }
  it "renders user json" do
    assign(:user,user)
    render :template => "rearview/user/show", :formats => :json, :handler => :jbuilder
    json = JSON.parse(rendered)
    expect(json).to be_a_kind_of(Hash)
    user_keys.each { |k| expect(json).to include(k) }
    expect(json.keys.size).to eq(user_keys.size)
  end
end

