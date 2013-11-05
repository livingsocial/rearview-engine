module AuthenticationHelper

  def sign_in_as(user)
    controller.stubs(:user_signed_in?).returns(true)
    controller.stubs(:current_user).returns(user)
    controller.stubs(:authenticate_user!).returns(true)
    session[:user_id] = user.id
  end

end

RSpec.configure do |config|
  config.include AuthenticationHelper, :type => :controller
end
