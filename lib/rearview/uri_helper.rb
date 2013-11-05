module Rearview
  class UriHelper
    def self.rearview_uri(job)
      "https://rearview.livingsocial.net/#dash/#{job.app_id}/expand/#{job.id}"
    end
  end
end
