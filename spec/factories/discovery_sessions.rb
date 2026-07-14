# frozen_string_literal: true

FactoryBot.define do
  factory :discovery_session do
    association :profile
    messages { [] }
    status { 'active' }
    turn_count { 0 }

    trait :drafted do
      status { 'drafted' }
      association :smart_goal
    end

    trait :near_cap do
      turn_count { 6 }
    end
  end
end
