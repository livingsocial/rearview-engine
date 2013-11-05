# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user, class: Rearview::User do
    created_at                    Time.now.utc
    updated_at                    Time.now.utc
    preferences                   pref1: :pref1, pref2: :pref2
    sequence(:email)              { |n| "user#{n}@hungrymachine.com" }
    sequence(:first_name)         { |n| "first_name#{n}" }
    sequence(:last_name)          { |n| "last_name#{n}" }
  end
end
