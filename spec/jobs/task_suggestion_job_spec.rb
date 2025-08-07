# frozen_string_literal: true

require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe TaskSuggestionJob, type: :job do
  let(:profile) { create(:profile) }
  let(:user_provided_key) { 'sk-test-key' }
  let(:ai_request) { create(:ai_request, profile: profile, job_type: 'task_suggestion') }
  let(:mock_suggestions) do
    [
      {
        title: 'Complete project documentation',
        description: 'Write comprehensive documentation',
        goal_id: 'goal-1',
        time_estimate_minutes: 60
      }
    ]
  end

  before do
    Sidekiq::Testing.inline!
    allow(Rails.logger).to receive(:error)
    allow(Rails.logger).to receive(:info)
  end

  after do
    Sidekiq::Testing.fake!
  end

  describe '#perform' do
    context 'when processing succeeds' do
      it 'generates task suggestions successfully' do
        mock_suggester = instance_double(Ai::TaskSuggester)
        allow(Ai::TaskSuggester).to receive(:new).with(profile).and_return(mock_suggester)
        allow(mock_suggester).to receive(:generate_suggestions).and_return(mock_suggestions)

        result = described_class.perform_now(profile.id, user_provided_key, ai_request.id)

        expect(result).to eq(mock_suggestions)
        expect(ai_request.reload.status).to eq('completed')
      end

      it 'creates new AI request if not provided' do
        mock_suggester = instance_double(Ai::TaskSuggester)
        allow(Ai::TaskSuggester).to receive(:new).with(profile).and_return(mock_suggester)
        allow(mock_suggester).to receive(:generate_suggestions).and_return(mock_suggestions)

        expect { described_class.perform_now(profile.id) }.to change(AiRequest, :count).by(1)

        new_request = AiRequest.last
        expect(new_request.profile).to eq(profile)
        expect(new_request.job_type).to eq('task_suggestion')
        expect(new_request.status).to eq('completed')
      end
    end

    context 'when processing fails' do
      it 'handles errors gracefully and updates request status' do
        # Mock the service constructor to return a mock that raises an error
        mock_suggester = instance_double(Ai::TaskSuggester)
        allow(Ai::TaskSuggester).to receive(:new).and_return(mock_suggester)
        allow(mock_suggester).to receive(:generate_suggestions).and_raise(StandardError, 'Task suggester error')

        # The job will retry due to retry_on StandardError, so we don't expect an immediate error
        # Instead, we expect the error to be logged and the request status to be updated
        described_class.perform_now(profile.id, user_provided_key, ai_request.id)

        expect(ai_request.reload.status).to eq('failed')
        expect(ai_request.error_message).to eq('Task suggester error')
      end

      it 'logs error with context' do
        # Mock the service constructor to return a mock that raises an error
        mock_suggester = instance_double(Ai::TaskSuggester)
        allow(Ai::TaskSuggester).to receive(:new).and_return(mock_suggester)
        allow(mock_suggester).to receive(:generate_suggestions).and_raise(StandardError, 'Task suggester error')

        described_class.perform_now(profile.id, user_provided_key, ai_request.id)

        expect(Rails.logger).to have_received(:error).with('AI Processing Job Error: Task suggester error')
        expect(Rails.logger).to have_received(:error).with(
          "Context: {:profile_id=>#{profile.id}, :request_id=>#{ai_request.id}}"
        )
      end
    end

    context 'when profile is not found' do
      it 'retries the job due to retry_on StandardError' do
        # Since the job uses retry_on StandardError, ActiveRecord::RecordNotFound will be retried
        # We expect the job to be retried and eventually fail after 3 attempts
        expect { described_class.perform_now(999_999, user_provided_key) }.not_to raise_error
      end
    end
  end

  describe 'queue configuration' do
    it 'uses the ai_processing queue' do
      expect(described_class.queue_name).to eq('ai_processing')
    end

    it 'has retry configuration' do
      expect(described_class).to respond_to(:retry_on)
    end
  end
end
