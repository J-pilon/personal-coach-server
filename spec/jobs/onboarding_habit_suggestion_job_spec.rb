# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OnboardingHabitSuggestionJob do
  let(:profile) { create(:user).profile }
  let(:smart_goal) { create(:smart_goal, profile: profile) }
  let(:ai_request) do
    AiRequest.create!(profile: profile, prompt: 'pending', job_type: 'onboarding_habit_suggestion', status: 'pending')
  end
  let(:client) { instance_double(Ai::OpenAiClient) }

  before do
    allow(Ai::OpenAiClient).to receive(:new).and_return(client)
    allow_any_instance_of(described_class).to receive(:store) # rubocop:disable RSpec/AnyInstance
  end

  def valid_habit(title = 'Walk')
    {
      'title' => title,
      'frequency' => 'daily',
      'frequency_config' => {},
      'cue' => 'after coffee',
      'minimum_version' => '1 min stroll',
      'normal_version' => '15 min walk'
    }
  end

  it 'completes on 3 valid habits' do
    allow(client).to receive(:chat_completion).and_return(
      'habits' => [valid_habit('A'), valid_habit('B'), valid_habit('C')]
    )

    described_class.new.perform(smart_goal_id: smart_goal.id, ai_request_id: ai_request.id)

    expect(ai_request.reload.status).to eq('completed')
  end

  it 'expects 1 habit when position given' do
    allow(client).to receive(:chat_completion).and_return('habits' => [valid_habit('Only')])

    described_class.new.perform(smart_goal_id: smart_goal.id, ai_request_id: ai_request.id, position: 2)

    expect(ai_request.reload.status).to eq('completed')
  end

  it 'fails on wrong habit count' do
    allow(client).to receive(:chat_completion).and_return('habits' => [valid_habit, valid_habit])

    expect do
      described_class.new.perform(smart_goal_id: smart_goal.id, ai_request_id: ai_request.id)
    end.to raise_error(OnboardingHabitSuggestionJob::InvalidAiResponseError)

    expect(ai_request.reload.status).to eq('failed')
  end

  it 'fails on invalid frequency' do
    bad = valid_habit.merge('frequency' => 'never')
    allow(client).to receive(:chat_completion).and_return('habits' => [bad, valid_habit, valid_habit])

    expect do
      described_class.new.perform(smart_goal_id: smart_goal.id, ai_request_id: ai_request.id)
    end.to raise_error(OnboardingHabitSuggestionJob::InvalidAiResponseError)
  end

  it 'fails on banned content' do
    banned = valid_habit.merge('cue' => 'diagnose yourself daily')
    allow(client).to receive(:chat_completion).and_return('habits' => [banned, valid_habit, valid_habit])

    expect do
      described_class.new.perform(smart_goal_id: smart_goal.id, ai_request_id: ai_request.id)
    end.to raise_error(OnboardingHabitSuggestionJob::InvalidAiResponseError, /banned/)
  end
end
