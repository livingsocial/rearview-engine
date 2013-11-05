module Rearview::Concerns::Models::User
  extend ActiveSupport::Concern
  included do

    self.table_name = "users"

    has_many :monitors, :dependent => :destroy

    serialize :preferences, JSON

    validates_uniqueness_of :email
    validates_presence_of :email

  end
end
