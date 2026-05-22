# frozen_string_literal: true

FactoryBot.define do
  factory :journal_entry do
    association :profile
    journal { association(:journal, profile: profile) }
    title { 'Today' }
    body { 'A quick reflection on the day.' }
    entry_type { 'daily_journal' }
    occurred_on { Date.current }

    trait :weekly do
      entry_type { 'weekly_reflection' }
      title { 'Week in review' }
    end

    trait :general do
      entry_type { 'general' }
    end
  end
end
