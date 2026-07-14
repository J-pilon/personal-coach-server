# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ai::PromptTemplates::OnboardingGoalDiscoveryPrompt do
  it 'includes the propose-not-author methodology instruction' do
    text = described_class.new(messages: []).build

    expect(text).to include('Propose, do not author')
    expect(text).to include('user must approve')
  end

  it 'declares both allowed JSON shapes' do
    text = described_class.new(messages: []).build

    expect(text).to include('"kind": "question"')
    expect(text).to include('"kind": "smart_goal_draft"')
    %w[title why specific measurable time_bound target_date timeframe].each do |k|
      expect(text).to include("\"#{k}\"")
    end
  end

  it 'includes the today + 7 days target-date clamp language' do
    text = described_class.new(messages: []).build

    expect(text).to include('at least 7 days after today').or include('today + 7 days')
  end

  it 'forces smart_goal_draft on the final turn' do
    text = described_class.new(messages: [], force_draft: true).build

    expect(text).to include('MUST return Shape B')
  end

  it 'suggests a draft when enough info without forcing' do
    text = described_class.new(messages: []).build

    expect(text).to include('prefer Shape B').or include('you have enough to draft')
  end

  it 'renders the transcript' do
    text = described_class.new(messages: [{ 'role' => 'user', 'text' => 'run 10k' }]).build

    expect(text).to include('user: run 10k')
  end
end
