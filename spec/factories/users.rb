FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { 'password123' }
    password_confirmation { 'password123' }

    trait :with_profile do
      after(:create) do |user|
        create(:profile, user: user)
      end
    end

    trait :with_tasks do
      after(:create) do |user|
        create_list(:task, 3, profile: user.profile)
      end
    end

    trait :with_smart_goals do
      after(:create) do |user|
        create_list(:smart_goal, 2, profile: user.profile)
      end
    end
  end
end
