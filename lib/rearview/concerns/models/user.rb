module Rearview::Concerns::Models::User
  extend ActiveSupport::Concern
  included do

    self.table_name = "users"

    has_many :monitors, :dependent => :destroy

    serialize :preferences, JSON

    validates_uniqueness_of :email
    validates_presence_of :email

    def self.valid_google_oauth2_email?(email)
      email.present? &&
      Rearview.config.authentication[:matching_emails].present? &&
      !email.match(Rearview.config.authentication[:matching_emails]).nil?
    end

  end
end
