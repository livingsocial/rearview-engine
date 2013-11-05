module Rearview
  module Alerts
    class Base
      include Rearview::Logger

      def self.valid_scheme?(s)
        s.present? && s.downcase == scheme
      end

      def self.key_to_params(key)
        if key.kind_of?(Hash)
          key
        else
          self.params(key)
        end
      end

    end
  end
end
