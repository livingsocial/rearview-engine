
module Rearview
  class MetricsValidationMailer < ActionMailer::Base
    default from: Rearview.config.default_from
    def validation_failed_email(recipient, job)
      @job = job
      mail(:to => recipient, :subject => "[Rearview ALERT] invalid metrics for #{@job.name}")
    end
  end
end


