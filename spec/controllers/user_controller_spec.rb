require 'spec_helper'

describe Rearview::UserController do
  let(:user) {
    create(:user)
  }
  before do
    @routes = Rearview::Engine.routes
    sign_in_as user
  end
  context "GET /user" do
    it "renders the show view" do
      get :show, format: :json
      render_template(:show)
    end
  end
  context "PUT /user" do
    it "renders the show view" do
      controller.stubs(:current_user).returns(user)
      json = JsonFactory::User.update(user)
      JSON.stubs(:parse).returns(preferences: json["preferences"])
      user.expects(:save!)
      put :update, json 
      render_template(:show)
    end
  end
end
