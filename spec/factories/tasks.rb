# frozen_string_literal: true

FactoryBot.define do
  factory :task do
    title { Faker::Lorem.sentence(word_count: 3) }
    description { Faker::Lorem.paragraph(sentence_count: 2) }
    completed { false }
    action_category { Task.action_categories.keys.sample }

    trait :completed do
      completed { true }
    end

    trait :with_long_title do
      title { Faker::Lorem.sentence(word_count: 10) }
    end

    trait :with_long_description do
      description { Faker::Lorem.paragraph(sentence_count: 5) }
    end
  end
end
