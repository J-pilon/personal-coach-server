# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ai::PromptTemplates::SingleSmartGoalPrompt do
  describe '#build' do
    let(:user_input) { 'I want to learn Spanish' }
    let(:timeframe) { '3 months' }
    let(:context) { 'Current Goals: Exercise daily' }

    context 'with user input, timeframe, and context' do
      let(:prompt) { described_class.new(user_input, timeframe, context).build }

      it 'includes SMART goal instructions' do
        expect(prompt).to include('SMART goals must be:')
        expect(prompt).to include('Specific:')
        expect(prompt).to include('Measurable:')
        expect(prompt).to include('Achievable:')
        expect(prompt).to include('Relevant:')
        expect(prompt).to include('Time-bound:')
      end

      it 'includes user input' do
        expect(prompt).to include('User Input: "I want to learn Spanish"')
      end

      it 'includes timeframe' do
        expect(prompt).to include('Timeframe: 3 months')
      end

      it 'includes context' do
        expect(prompt).to include('Recent Goals and Tasks:')
        expect(prompt).to include('Current Goals: Exercise daily')
      end

      it 'includes JSON structure instructions' do
        expect(prompt).to include('"specific":')
        expect(prompt).to include('"measurable":')
        expect(prompt).to include('"achievable":')
        expect(prompt).to include('"relevant":')
        expect(prompt).to include('"time_bound":')
      end

      it 'instructs to return only JSON' do
        expect(prompt).to include('Return ONLY a JSON object')
        expect(prompt).to include('Do not include any explanatory text outside the JSON structure')
      end
    end

    context 'with user input and timeframe but no context' do
      let(:prompt) { described_class.new(user_input, timeframe, '').build }

      it 'indicates no context provided' do
        expect(prompt).to include('No additional context provided.')
      end

      it 'still includes user input' do
        expect(prompt).to include('User Input: "I want to learn Spanish"')
      end

      it 'still includes timeframe' do
        expect(prompt).to include('Timeframe: 3 months')
      end
    end

    context 'with user input and context but no timeframe' do
      let(:prompt) { described_class.new(user_input, nil, context).build }

      it 'uses default timeframe' do
        expect(prompt).to include('Timeframe: 1 month')
      end

      it 'includes user input' do
        expect(prompt).to include('User Input: "I want to learn Spanish"')
      end

      it 'includes context' do
        expect(prompt).to include('Recent Goals and Tasks:')
        expect(prompt).to include('Current Goals: Exercise daily')
      end
    end

    context 'with empty user input' do
      let(:prompt) { described_class.new('', timeframe, context).build }

      it 'handles empty input gracefully' do
        expect(prompt).to include('User Input: ""')
        expect(prompt).to include('Timeframe: 3 months')
        expect(prompt).to include('Current Goals: Exercise daily')
      end
    end

    context 'with special characters in input' do
      let(:user_input) { 'I want to "learn" Spanish & French!' }
      let(:prompt) { described_class.new(user_input, timeframe, context).build }

      it 'preserves special characters' do
        expect(prompt).to include('User Input: "I want to "learn" Spanish & French!"')
      end
    end

    context 'with different timeframes' do
      it 'handles various timeframe values' do
        prompt = described_class.new(user_input, '6 weeks', context).build
        expect(prompt).to include('Timeframe: 6 weeks')
      end

      it 'handles long timeframe values' do
        prompt = described_class.new(user_input, '1 year', context).build
        expect(prompt).to include('Timeframe: 1 year')
      end
    end
  end
end
