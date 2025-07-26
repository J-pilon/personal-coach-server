# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ai::TaskSuggester do
  let(:profile) { create(:profile) }
  let(:task_suggester) { described_class.new(profile) }

  describe '#generate_suggestions' do
    let!(:task) { create(:task, profile: profile, title: 'Existing task', completed: false) }
    let!(:smart_goal) { create(:smart_goal, profile: profile, title: 'Test Goal') }

    it 'returns an array of task suggestions' do
      mock_suggestions = [
        {
          'title' => 'Update portfolio README',
          'description' => 'Clarify project goals',
          'goal_id' => smart_goal.id.to_s,
          'time_estimate_minutes' => 30
        }
      ]

      allow_any_instance_of(Ai::OpenAiClient).to receive(:chat_completion).and_return(mock_suggestions)

      result = task_suggester.generate_suggestions

      expect(result).to be_an(Array)
      expect(result.first[:title]).to eq('Update portfolio README')
      expect(result.first[:time_estimate_minutes]).to eq(30)
    end

    it 'creates an AI request record' do
      mock_suggestions = [{ 'title' => 'Test task', 'description' => 'Test', 'goal_id' => nil, 'time_estimate_minutes' => 30 }]
      allow_any_instance_of(Ai::OpenAiClient).to receive(:chat_completion).and_return(mock_suggestions)

      expect { task_suggester.generate_suggestions }.to change(AiRequest, :count).by(1)

      ai_request = AiRequest.last
      expect(ai_request.job_type).to eq('task_suggestion')
      expect(ai_request.status).to eq('completed')
    end

    context 'when AI service fails' do
      it 'raises an error and marks request as failed' do
        allow_any_instance_of(Ai::OpenAiClient).to receive(:chat_completion).and_raise(StandardError, 'AI service error')

        expect { task_suggester.generate_suggestions }.to raise_error(StandardError)

        ai_request = AiRequest.last
        expect(ai_request.status).to eq('failed')
        expect(ai_request.error_message).to eq('AI service error')
      end
    end
  end
end
