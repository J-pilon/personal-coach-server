# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ai::AiService do
  let(:user) { create(:user) }
  let(:profile) { user.profile }
  let(:mock_open_ai_client) { instance_double(Ai::OpenAiClient) }
  let(:timeframe) { '1 month' }

  before do
    allow(Ai::OpenAiClient).to receive(:new).and_return(mock_open_ai_client)
  end

  describe '#process' do
    context 'when processing smart goal intent' do
      let(:service) { described_class.new(profile: profile, intent: :smart_goal) }
      let(:input) { 'I want to create a goal to exercise more' }
      let(:context) { 'Current Goals: Exercise daily' }
      let(:ai_response) { { 'specific' => 'Exercise for 30 minutes daily' } }

      before do
        allow(Ai::ContextCompressor).to receive(:perform).with(profile).and_return(context)
        allow(mock_open_ai_client).to receive(:chat_completion).and_return(ai_response)
      end

      it 'returns structured response with smart_goal intent' do
        result = service.process(input, timeframe)

        expect(result[:intent]).to eq(:smart_goal)
        expect(result[:response]).to eq(ai_response)
        expect(result[:context_used]).to be true
        expect(result[:request_id]).to be_present
      end

      it 'creates an AiRequest record with correct attributes' do
        expect { service.process(input, timeframe) }.to change(AiRequest, :count).by(1)

        ai_request = AiRequest.last
        expect(ai_request.profile_id).to eq(profile.id)
        expect(ai_request.job_type).to eq('smart_goal')
        expect(ai_request.status).to eq('completed')
        expect(ai_request.prompt).to be_present
      end

      it 'updates AiRequest with completed status' do
        result = service.process(input, timeframe)

        ai_request = AiRequest.find(result[:request_id])
        expect(ai_request.status).to eq('completed')
        expect(ai_request.error_message).to be_nil
      end

      it 'calls the appropriate prompt template' do
        allow(mock_open_ai_client).to receive(:chat_completion).and_return(ai_response)

        service.process(input, timeframe)

        expect(mock_open_ai_client).to have_received(:chat_completion).with(include('SMART goal creation'))
      end
    end

    context 'when processing prioritization intent' do
      let(:service) { described_class.new(profile: profile, intent: :prioritization) }
      let(:input) { 'Prioritize my tasks: exercise, work, sleep' }
      let(:context) { 'Recent Tasks: Exercise daily' }
      let(:ai_response) { [{ 'task' => 'exercise', 'priority' => 1 }] }

      before do
        allow(Ai::ContextCompressor).to receive(:perform).with(profile).and_return(context)
        allow(mock_open_ai_client).to receive(:chat_completion).and_return(ai_response)
      end

      it 'returns structured response with prioritization intent' do
        result = service.process(input, timeframe)

        expect(result[:intent]).to eq(:prioritization)
        expect(result[:response]).to eq(ai_response)
        expect(result[:context_used]).to be true
        expect(result[:request_id]).to be_present
      end

      it 'creates an AiRequest record with prioritization job type' do
        expect { service.process(input, timeframe) }.to change(AiRequest, :count).by(1)

        ai_request = AiRequest.last
        expect(ai_request.profile_id).to eq(profile.id)
        expect(ai_request.job_type).to eq('prioritization')
        expect(ai_request.status).to eq('completed')
        expect(ai_request.prompt).to be_present
      end

      it 'updates AiRequest with completed status' do
        result = service.process(input, timeframe)

        ai_request = AiRequest.find(result[:request_id])
        expect(ai_request.status).to eq('completed')
        expect(ai_request.error_message).to be_nil
      end

      it 'calls the appropriate prompt template' do
        allow(mock_open_ai_client).to receive(:chat_completion).and_return(ai_response)

        service.process(input, timeframe)

        expect(mock_open_ai_client).to have_received(:chat_completion).with(include('task prioritization'))
      end
    end

    context 'when context is empty' do
      let(:service) { described_class.new(profile: profile, intent: :smart_goal) }
      let(:input) { 'Create a goal' }
      let(:ai_response) { { 'specific' => 'Test goal' } }

      before do
        allow(Ai::ContextCompressor).to receive(:perform).with(profile).and_return('')
        allow(mock_open_ai_client).to receive(:chat_completion).and_return(ai_response)
      end

      it 'indicates no context was used' do
        result = service.process(input, timeframe)

        expect(result[:context_used]).to be false
      end
    end

    context 'when an error occurs' do
      let(:service) { described_class.new(profile: profile, intent: :smart_goal) }
      let(:input) { 'Create a goal' }

      before do
        allow(Ai::ContextCompressor).to receive(:perform).with(profile).and_raise(StandardError, 'Test error')
      end

      it 'returns error response' do
        result = service.process(input, timeframe)

        expect(result[:intent]).to eq(:error)
        expect(result[:response][:error]).to eq('Test error')
        expect(result[:context_used]).to be false
        expect(result[:request_id]).to be_nil
      end

      it 'does not create an AiRequest record when error occurs before creation' do
        expect { service.process(input, timeframe) }.not_to change(AiRequest, :count)

        expect(AiRequest.count).to eq(0)
      end
    end

    context 'when OpenAI client raises an error' do
      let(:service) { described_class.new(profile: profile, intent: :smart_goal) }
      let(:input) { 'Create a goal' }

      before do
        allow(Ai::ContextCompressor).to receive(:perform).with(profile).and_return('')
        allow(mock_open_ai_client).to receive(:chat_completion).and_raise(
          Ai::OpenAiClient::AiServiceError, 'OpenAI API error'
        )
      end

      it 'returns error response' do
        result = service.process(input, timeframe)

        expect(result[:intent]).to eq(:error)
        expect(result[:response][:error]).to eq('OpenAI API error')
        expect(result[:request_id]).to be_present
      end

      it 'creates an AiRequest record and updates it with failure status' do
        expect { service.process(input, timeframe) }.to change(AiRequest, :count).by(1)

        ai_request = AiRequest.last
        expect(ai_request.profile_id).to eq(profile.id)
        expect(ai_request.status).to eq('failed')
        expect(ai_request.error_message).to eq('OpenAI API error')
      end
    end
  end
end
