# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :job_error, class: Rearview::JobError do
    job
    created_at                    Time.now.utc
    last_alerted_at               nil
    sequence(:message)            { |n| "message#{n}" }
    status                        Rearview::JobError::Status::FAILED
  end
end
