java_import 'org.apache.commons.validator.EmailValidator'

module Rearview
  module Alerts
    class EmailAlert < Base

      def alert(job, result)
        job.alert_keys.each do |key|
          params = EmailAlert.params(key)
          if EmailAlert.key?(params)
            logger.info "#{self} send alert for #{job.inspect} and key #{key} with params #{params}"
            AlertMailer.alert_email(params["email"], job, result).deliver
          end
        end
      end

      def self.params(key)
        uri = URI(key)
        if uri.scheme.present?
          {
            "scheme" => uri.scheme,
            "email" => uri.opaque,
          }
        end
      rescue
        {}
      end

      def self.key?(key)
        p = key_to_params(key)
        valid_scheme?(p["scheme"]) && valid_email?(p["email"])
      end

      def self.valid_email?(email)
        EmailValidator.getInstance.isValid(email)
      end

      def self.scheme
        "mailto"
      end

    end
  end
end
