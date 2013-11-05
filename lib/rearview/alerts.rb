require 'rearview/alerts/base'
require 'rearview/alerts/email_alert'
require 'rearview/alerts/pagerduty_alert'
require 'rearview/alerts/campfire_alert'

module Rearview
  module Alerts
    module_function
    def registry
      unless @registry
        @registry = {}.tap do |h|
          h[Rearview::Alerts::PagerDutyAlert.scheme] = Rearview::Alerts::PagerDutyAlert
          h[Rearview::Alerts::EmailAlert.scheme] = Rearview::Alerts::EmailAlert
          h[Rearview::Alerts::CampfireAlert.scheme] = Rearview::Alerts::CampfireAlert
        end
      end
      @registry
    end
  end
end
