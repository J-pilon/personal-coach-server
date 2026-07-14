# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ai::PromptTemplates::OnboardingHabitSuggestionsPrompt do
  let(:goal) { build(:smart_goal, title: 'Run a 10k', why: 'health') }

  it 'includes propose-not-author methodology' do
    text = described_class.new(smart_goal: goal).build
    expect(text).to include('Propose, do not author')
  end

  it 'declares the minute constraints' do
    text = described_class.new(smart_goal: goal).build
    expect(text).to include('under 2 minutes')
    expect(text).to include('under 20 minutes')
  end

  it 'requires cue tied to a routine' do
    text = described_class.new(smart_goal: goal).build
    expect(text).to include('existing daily routine')
  end

  it 'defaults to exactly 3 habits' do
    text = described_class.new(smart_goal: goal).build
    expect(text).to include('exactly 3 habits')
  end

  it 'returns exactly 1 habit when position is given' do
    text = described_class.new(smart_goal: goal, position: 2).build
    expect(text).to include('exactly 1 habit')
    expect(text).to include('position 2')
  end

  it 'lists excluded titles' do
    text = described_class.new(smart_goal: goal, exclude: ['Meditate 5 min']).build
    expect(text).to include('Meditate 5 min')
  end

  it 'declares banned-content post-processing' do
    text = described_class.new(smart_goal: goal).build
    expect(text).to include('Banned content')
  end
end
