require 'broach'

module Rearview
  module Alerts
    class CampfireAlert < Base

      def alert(job, result)
        job.alert_keys.each do |key|
          params = CampfireAlert.params(key)
          if CampfireAlert.key?(params)
            logger.info "#{self} send alert for #{job.inspect} and key #{key} with params #{params}"
            Broach.settings = params
            Broach.speak(params["room"], alert_msg(job, result))
          end
        end
      end

      private

      def alert_msg(job, result)
        msg = result[:message] ? result[:message] : "Job did not provide an error description"
        "#{msg} #{Rearview::UrlHelper.job_url(job)}"
      end

      def self.params(key)
        uri = URI(key)
        query_params = CGI.parse(uri.query)
        {
          "scheme" =>  uri.scheme,
          "account" => uri.host,
          "token" => query_params["token"].first,
          "room" => query_params["room"].first,
          "use_ssl" => true
        }
      rescue
        {}
      end

      def self.key?(key)
        p = key_to_params(key)
        valid_scheme?(p["scheme"]) && p["token"].present? && p["room"].present?
      end

      def self.scheme
        "campfire"
      end

    end
  end
end
