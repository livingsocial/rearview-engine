# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :job, class: Rearview::Job do
    sequence(:id)
    user
    dashboard
    created_at                    Time.now.utc
    updated_at                    Time.now.utc
    sequence(:name)               { |n| "job#{n}" }
    active                        1
    cron_expr                     "0 * * * * ?"
    error_timeout                 60
    metrics                       ["stats_counts.cupcake.web_traffic.impression"]
    monitor_expr                  "puts 'hello, world!'"
    minutes                       1
    alert_keys                    ["mailto:foo@hungrymachine.com","pagerduty:54232f6f4c4447efb6d15e20dbb7349c"]
  end

end
