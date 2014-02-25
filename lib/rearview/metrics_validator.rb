module Rearview
  class MetricsValidator < ActiveModel::EachValidator
    attr_accessor :message
    def validate_each(record, attribute, value)
      if value.present? && value.respond_to?(:each)
        value.each do |metric|
          unless metric_valid?(metric)
            record.errors.add(attribute,(message || "contains an invalid metric: #{metric}"))
            message = nil
          end
        end
      end
    end
    def metric_valid?(metric)
      valid = false
      metric_key = nil
      target_parser.parse(metric)
      if target_parser.error?
        message = "contains an unparseable metric: #{metric} (#{target_parser.error})"  
      else
        if target_parser.tree.comment? 
          valid = true
        else
          metric_key = target_parser.tree.metric
          if metric_key.present?
            if cache?
              unless cache.has_key?(metric_key)
                cache[metric_key] = client.metric_exists?(metric_key)
              end
              valid = cache[metric_key]
            else
              valid = client.metric_exists?(metric_key)
            end
          end
        end
      end
      valid
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
    def target_parser
      @target_parser ||= Graphite::TargetParser.new
    end
  end
end
