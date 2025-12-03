# frozen_string_literal: true

FactoryBot.define do
  factory :notification_preference do
    association :profile
    push_enabled { true }
    email_enabled { true }
    sms_enabled { false }
    preferred_time { '09:00' }
    timezone { 'UTC' }
  end
end
