# frozen_string_literal: true

FactoryBot.define do
  factory :notification_schedule do
    association :profile
    kind { 'daily_check_in' }
    local_time { '08:00' }
    timezone { 'UTC' }
    active { true }

    trait :inactive do
      active { false }
    end
  end
end
