# frozen_string_literal: true

FactoryBot.define do
  factory :device_token do
    association :profile
    token { "ExponentPushToken[#{SecureRandom.hex(20)}]" }
    platform { %w[ios android].sample }
    device_name { 'iPhone 15 Pro' }
    app_version { '1.0.0' }
    active { true }

    trait :inactive do
      active { false }
    end

    trait :web do
      platform { 'web' }
      endpoint { 'https://push.example.com/send/token123' }
      p256dh { SecureRandom.base64(32) }
      auth { SecureRandom.base64(16) }
    end
  end
end
