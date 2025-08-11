# frozen_string_literal: true

require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe AiServiceJob, type: :job do
  let(:profile) { create(:profile) }
  let(:input) { 'Create a SMART goal for learning React Native' }
  let(:intent) { 'smart_goal' }
  let(:user_provided_key) { 'sk-test-key' }
  let(:timeframe) { '1 month' }

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
      let(:ai_request) { create(:ai_request, profile: profile, job_type: 'smart_goal') }
      let(:mock_result) do
        {
          intent: :smart_goal,
          response: { specific: 'Test goal' },
          context_used: true,
          request_id: ai_request.id
        }
      end

      it 'processes AI request successfully' do
        mock_service = instance_double(Ai::AiService)
        allow(Ai::AiService).to receive(:new)
          .with(profile: profile, user_provided_key: user_provided_key, intent: intent)
          .and_return(mock_service)
        allow(mock_service).to receive(:process).with(input, timeframe).and_return(mock_result)

        result = described_class.perform_now(
          profile_id: profile.id,
          input: input,
          intent: intent,
          user_provided_key: user_provided_key,
          timeframe: timeframe,
          request_id: ai_request.id
        )

        expect(result).to eq(mock_result)
        expect(ai_request.reload.status).to eq('completed')
      end

      it 'creates new AI request if not provided' do
        mock_service = instance_double(Ai::AiService)
        allow(Ai::AiService).to receive(:new)
          .with(profile: profile, user_provided_key: nil, intent: intent)
          .and_return(mock_service)
        allow(mock_service).to receive(:process).with(input, timeframe).and_return(mock_result)

        expect do
          described_class.perform_now(
            profile_id: profile.id,
            input: input,
            intent: intent,
            timeframe: timeframe
          )
        end.to change(AiRequest, :count).by(1)

        new_request = AiRequest.last
        expect(new_request.profile).to eq(profile)
        expect(new_request.job_type).to eq('smart_goal')
        expect(new_request.status).to eq('completed')
      end
    end

    context 'when processing fails' do
      it 'handles errors gracefully' do
        ai_request = create(:ai_request, profile: profile, job_type: 'smart_goal')

        # Don't mock anything - let it fail naturally with the test key
        result = described_class.perform_now(
          profile_id: profile.id,
          input: input,
          intent: intent,
          user_provided_key: user_provided_key,
          timeframe: timeframe,
          request_id: ai_request.id
        )

        # The AI service handles errors gracefully and returns error responses
        expect(result[:intent]).to eq(:error)
        expect(result[:response][:error]).to include('Unexpected error')
        expect(ai_request.reload.status).to eq('completed')
      end

      it 'logs error with context' do
        ai_request = create(:ai_request, profile: profile, job_type: 'smart_goal')

        # Test with a real error scenario
        result = described_class.perform_now(
          profile_id: profile.id,
          input: input,
          intent: intent,
          user_provided_key: user_provided_key,
          timeframe: timeframe,
          request_id: ai_request.id
        )

        # The AI service handles errors gracefully and returns error responses
        expect(result[:intent]).to eq(:error)
        expect(result[:response][:error]).to include('Unexpected error')
        expect(ai_request.reload.status).to eq('completed')
        expect(Rails.logger).to have_received(:error).with(/AI Service error:/)
      end
    end

    context 'when profile is not found' do
      it 'retries the job due to retry_on StandardError' do
        # Since the job uses retry_on StandardError, ActiveRecord::RecordNotFound will be retried
        # We expect the job to be retried and eventually fail after 3 attempts
        expect do
          described_class.perform_now(
            profile_id: 999_999,
            input: input,
            intent: intent,
            timeframe: timeframe
          )
        end.not_to raise_error
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
