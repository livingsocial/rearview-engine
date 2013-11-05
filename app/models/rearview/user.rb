module Rearview
  class User < ActiveRecord::Base
    include Rearview::Concerns::Models::User
  end
end
