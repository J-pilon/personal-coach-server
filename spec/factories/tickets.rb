FactoryBot.define do
  factory :ticket do
    association :profile
    kind { 'bug' }
    title { 'Test Bug Report' }
    description { 'This is a test bug report with detailed description of the issue.' }
    source { 'app' }
    metadata { { app_version: '1.0.0', device_model: 'iPhone 14' } }

    trait :feedback do
      kind { 'feedback' }
      title { 'Feature Request' }
      description { 'This is a feature request with detailed feedback.' }
    end

    trait :web_source do
      source { 'web' }
    end
  end
end
