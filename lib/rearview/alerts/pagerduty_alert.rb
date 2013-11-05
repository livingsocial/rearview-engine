require 'json'

module Rearview
  module Alerts
    class PagerDutyAlert < Base

      def alert(job, result)
        job.alert_keys.each do |key|
          params = PagerDutyAlert.params(key)
          if PagerDutyAlert.key?(params)
            logger.info "#{self} send alert for #{job.inspect} and key #{key} with params #{params}"
            pagerduty_uri = Rearview.config.pagerduty_url
            job_uri       = Rearview::UriHelper.rearview_uri(job)
            msg           = result[:message]

            description = if msg
                            "#{msg.first(1024)} #{job_uri}"
                          else
                            "Rearview job #{job.id} #{job_uri}"
                          end

            options = { :body =>
              {
                :service_key  => params["token"],
                :event_type   => "trigger",
                :incident_key => "rearview/#{job.id}",
                :description  => description,
                :details     => result
              }.to_json
            }

            HTTParty.post(pagerduty_uri, options)
          end
        end
      end

      def self.params(key)
        uri = URI(key)
        if uri.scheme.present?
          {
            "scheme" => uri.scheme,
            "token" => uri.opaque,
          }
        end
      rescue
        {}
      end

      def self.key?(key)
        p = key_to_params(key)
        valid_scheme?(p["scheme"]) && valid_token?(p["token"])
      end

      def self.valid_token?(token)
        token.present? && token.match(/^\h{32}$/)
      end

      def self.scheme
        "pagerduty"
      end

    end
  end
end

