# frozen_string_literal: true

FactoryBot.define do
  factory :notification do
    association :profile
    notification_type { 'daily_reminder' }
    channel { 'push' }
    title { 'Daily Check-in' }
    body { "Don't forget to review your goals today!" }
    status { 'pending' }
    scheduled_for { 1.hour.from_now }

    trait :sent do
      status { 'sent' }
      sent_at { Time.current }
    end

    trait :failed do
      status { 'failed' }
      error_message { 'Device token expired' }
    end

    trait :email do
      channel { 'email' }
    end

    trait :task_reminder do
      notification_type { 'task_reminder' }
      title { 'Task Reminder' }
      body { 'You have pending tasks to complete' }
    end
  end
end
