java_import "org.apache.commons.validator.EmailValidator"

module Rearview
  class AlertMailer < ActionMailer::Base
    default from: Rearview.config.default_from
    def alert_email(recipient, job, result)
      @job    = job
      @result = result
      mail(:to => recipient, :subject => "[Rearview ALERT] #{job.name}")
    end
  end
end

