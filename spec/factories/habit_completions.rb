# frozen_string_literal: true

FactoryBot.define do
  factory :habit_completion do
    association :habit
    completed_on { Date.current }
    state { 'committed' }
    committed_at { Time.current }

    trait :completed_minimum do
      state { 'completed_minimum' }
      completed_at { Time.current }
    end

    trait :completed_normal do
      state { 'completed_normal' }
      completed_at { Time.current }
    end

    trait :skipped do
      state { 'skipped' }
    end
  end
end
