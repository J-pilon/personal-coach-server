# frozen_string_literal: true

FactoryBot.define do
  factory :habit do
    association :profile
    smart_goal { association :smart_goal, profile: profile }
    title { Faker::Lorem.sentence(word_count: 3) }
    frequency { 'daily' }
    frequency_config { {} }
    cue { Faker::Lorem.sentence(word_count: 4) }
    minimum_version { Faker::Lorem.sentence(word_count: 3) }
    normal_version { Faker::Lorem.sentence(word_count: 5) }
    sequence(:position) { |n| ((n - 1) % 3) + 1 }

    trait :archived do
      archived_at { Time.current }
    end

    trait :weekly do
      frequency { 'weekly_n_times' }
      frequency_config { { 'times_per_week' => 3 } }
    end
  end
end
