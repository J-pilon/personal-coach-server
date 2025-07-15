FactoryBot.define do
  factory :smart_goal do
    association :profile
    title { Faker::Lorem.sentence(word_count: 4) }
    description { Faker::Lorem.paragraph(sentence_count: 3) }
    timeframe { %w[1_month 3_months 6_months].sample }
    specific { Faker::Lorem.sentence(word_count: 6) }
    measurable { Faker::Lorem.sentence(word_count: 5) }
    achievable { Faker::Lorem.sentence(word_count: 4) }
    relevant { Faker::Lorem.sentence(word_count: 5) }
    time_bound { Faker::Lorem.sentence(word_count: 4) }
    completed { false }
    target_date { 3.months.from_now }

    trait :completed do
      completed { true }
    end

    trait :one_month do
      timeframe { '1_month' }
      target_date { 1.month.from_now }
    end

    trait :three_months do
      timeframe { '3_months' }
      target_date { 3.months.from_now }
    end

    trait :six_months do
      timeframe { '6_months' }
      target_date { 6.months.from_now }
    end
  end
end
