module Rearview
  class UrlHelper
    def self.job_url(job)
      Rails.application.routes.url_helpers.rearview_url(Rearview.config.default_url_options) + "/#dash/#{job.app_id}/expand/#{job.id}"
    end
  end
end
