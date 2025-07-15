FactoryBot.define do
  factory :profile do
    association :user
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    work_role { Faker::Job.title }
    education { Faker::Educator.degree }
    desires { Faker::Lorem.paragraph(sentence_count: 2) }
    limiting_beliefs { Faker::Lorem.paragraph(sentence_count: 1) }
    onboarding_status { 'incomplete' }

    trait :completed_onboarding do
      onboarding_status { 'complete' }
      onboarding_completed_at { Time.current }
    end

    trait :with_tasks do
      after(:create) do |profile|
        create_list(:task, 3, profile: profile)
      end
    end

    trait :with_smart_goals do
      after(:create) do |profile|
        create_list(:smart_goal, 2, profile: profile)
      end
    end
  end
end
