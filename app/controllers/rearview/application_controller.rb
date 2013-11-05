module Rearview
  class ApplicationController < ActionController::Base
    helper Rearview::Engine.helpers
    before_filter :authenticate_user!
  end
end
