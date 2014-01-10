module Rearview
  class UrlHelper
    def self.job_url(job)
      dashboard_id = if job.dashboard.root?
                      job.app_id
                     else
                      job.dashboard.parent.id
                     end
      [ Rails.application.routes.url_helpers.rearview_url(Rearview.config.default_url_options),
        "#dash",
        "#{dashboard_id}",
        "expand",
        "#{job.id}" ].join("/")
    end
  end
end
