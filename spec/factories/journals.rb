# frozen_string_literal: true

FactoryBot.define do
  factory :journal do
    association :profile
    title { 'My Journal' }
    description { 'Daily journals, weekly reflections, and goal notes.' }
    kind { 'default' }
  end
end
