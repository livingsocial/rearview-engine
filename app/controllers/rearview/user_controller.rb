require_dependency "rearview/application_controller"

module Rearview
  class UserController < Rearview::ApplicationController
    respond_to :json
    def show
      @user = current_user
    end
    def update
      # https://github.com/rails/rails/issues/8831
      # https://github.com/rails/rails/issues/8832
      preferences = JSON.parse(request.body.string).with_indifferent_access.try(:[],:preferences)
      @user = current_user
      if preferences.present?
        @user.preferences = preferences
        @user.save!
      end
      render :show
    end
  end
end
