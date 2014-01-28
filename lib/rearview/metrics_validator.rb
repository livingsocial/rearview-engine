module Rearview
  class MetricsValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
      if value.present? && value.respond_to?(:each)
        value.each do |metric|
          unless metric_valid?(metric)
            record.errors.add attribute,(options[:message] || "contains an invalid metric: #{metric}")
          end
        end
      end
    end
    def metric_valid?(metric)
      if cache?
        unless cache.has_key?(metric)
          cache[metric] = client.metric_exists?(metric)
        end
        cache[metric]
      else
        client.metric_exists?(metric)
      end
    end
    def cache?
      options[:cache]
    end
    def cache
      @cache ||= {}
    end
    def client
      @client ||= Graphite::Client.new(Rearview.config.graphite_connection)
    end
  end
end
