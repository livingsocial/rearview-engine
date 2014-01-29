module Rearview
  class CronExpressionValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
      if value.present?
        unless Rearview::CronHelper.valid_expression?(value)
          record.errors.add(attribute,(options[:message] || "is not a valid cron expression"))
        end
      end
    end
  end
end
