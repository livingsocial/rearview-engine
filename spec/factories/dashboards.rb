# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :dashboard, class: Rearview::Dashboard do
    user
    created_at                    Time.now.utc
    updated_at                    Time.now.utc
    sequence(:name)               { |n| "application#{n}" }
    sequence(:description)        { |n| "description#{n}" }
  end
end
