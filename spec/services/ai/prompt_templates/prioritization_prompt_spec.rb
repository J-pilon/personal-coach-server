# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ai::PromptTemplates::PrioritizationPrompt do
  describe '#build' do
    let(:tasks_input) { 'exercise, work, sleep' }
    let(:context) { 'Current Goals: Exercise daily' }

    context 'with tasks input and context' do
      let(:prompt) { described_class.new(tasks_input, context).build }

      it 'includes prioritization instructions' do
        expect(prompt).to include('task prioritization')
        expect(prompt).to include('Prioritization Criteria:')
        expect(prompt).to include('Urgency:')
        expect(prompt).to include('Importance:')
        expect(prompt).to include('Impact:')
        expect(prompt).to include('Dependencies:')
        expect(prompt).to include('Energy:')
      end

      it 'includes tasks input' do
        expect(prompt).to include('Tasks to Prioritize:')
        expect(prompt).to include('exercise, work, sleep')
      end

      it 'includes context' do
        expect(prompt).to include('User Context:')
        expect(prompt).to include('Current Goals: Exercise daily')
      end

      it 'includes JSON structure instructions' do
        expect(prompt).to include('"task":')
        expect(prompt).to include('"priority":')
        expect(prompt).to include('"rationale":')
        expect(prompt).to include('"recommended_action":')
      end

      it 'specifies priority levels' do
        expect(prompt).to include('Assign a priority level (1-5, where 1 is highest priority)')
      end

      it 'specifies recommended actions' do
        expect(prompt).to include('do|defer|delegate')
      end

      it 'instructs to return only JSON' do
        expect(prompt).to include('Return ONLY a JSON array')
        expect(prompt).to include('Do not include any explanatory text outside the JSON structure')
      end
    end

    context 'with tasks input but no context' do
      let(:prompt) { described_class.new(tasks_input, '').build }

      it 'indicates no context provided' do
        expect(prompt).to include('No additional context provided.')
      end

      it 'still includes tasks input' do
        expect(prompt).to include('Tasks to Prioritize:')
        expect(prompt).to include('exercise, work, sleep')
      end
    end

    context 'with empty tasks input' do
      let(:prompt) { described_class.new('', context).build }

      it 'handles empty input gracefully' do
        expect(prompt).to include('Tasks to Prioritize:')
        expect(prompt).to include('Current Goals: Exercise daily')
      end
    end

    context 'with complex task list' do
      let(:tasks_input) { "1. Buy groceries\n2. Call mom\n3. Finish report" }
      let(:prompt) { described_class.new(tasks_input, context).build }

      it 'preserves task formatting' do
        expect(prompt).to include('1. Buy groceries')
        expect(prompt).to include('2. Call mom')
        expect(prompt).to include('3. Finish report')
      end
    end

    context 'with special characters in tasks' do
      let(:tasks_input) { 'exercise & yoga, work (urgent), sleep!' }
      let(:prompt) { described_class.new(tasks_input, context).build }

      it 'preserves special characters' do
        expect(prompt).to include('exercise & yoga, work (urgent), sleep!')
      end
    end
  end
end
