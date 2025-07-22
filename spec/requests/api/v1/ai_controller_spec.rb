# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::AiController', type: :request do
  let(:user) { create(:user) }
  let(:headers) { { 'X-User-ID' => user.id.to_s } }

  describe 'POST /api/v1/ai' do
    context 'when user is authenticated' do
      let(:mock_ai_service) { instance_double(Ai::AiService) }

      before do
        allow(Ai::AiService).to receive(:new).and_return(mock_ai_service)
      end

      context 'with valid input' do
        let(:input) { 'Create a goal to exercise more' }
        let(:ai_response) do
          {
            intent: :smart_goal,
            response: {
              specific: 'Exercise for 30 minutes daily',
              measurable: 'Track workouts in fitness app',
              achievable: 'Start with 3 days per week',
              relevant: 'Improves overall health and energy',
              time_bound: 'Complete 30 workouts in 3 months'
            },
            context_used: true
          }
        end

        before do
          allow(mock_ai_service).to receive(:process).and_return(ai_response)
        end

        it 'returns successful response' do
          post '/api/v1/ai', params: { input: input }, headers: headers

          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)

          expect(json_response['intent']).to eq('smart_goal')
          expect(json_response['response']['specific']).to eq('Exercise for 30 minutes daily')
          expect(json_response['context_used']).to be true
        end

        it 'calls AiService with correct parameters' do
          expect(mock_ai_service).to receive(:process).with(input).and_return(ai_response)

          post '/api/v1/ai', params: { input: input }, headers: headers
        end
      end

      context 'with prioritization input' do
        let(:input) { 'Prioritize my tasks: exercise, work, sleep' }
        let(:ai_response) do
          {
            intent: :prioritization,
            response: [
              {
                task: 'exercise',
                priority: 1,
                rationale: 'High impact on health',
                recommended_action: 'do'
              }
            ],
            context_used: true
          }
        end

        before do
          allow(mock_ai_service).to receive(:process).and_return(ai_response)
        end

        it 'returns prioritization response' do
          post '/api/v1/ai', params: { input: input }, headers: headers

          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)

          expect(json_response['intent']).to eq('prioritization')
          expect(json_response['response']).to be_an(Array)
        end
      end

      context 'with empty input' do
        it 'returns bad request error' do
          post '/api/v1/ai', params: { input: '' }, headers: headers

          expect(response).to have_http_status(:bad_request)
          json_response = JSON.parse(response.body)
          expect(json_response['error']).to eq('Input is required')
        end
      end

      context 'with missing input parameter' do
        it 'returns bad request error' do
          post '/api/v1/ai', params: {}, headers: headers

          expect(response).to have_http_status(:bad_request)
          json_response = JSON.parse(response.body)
          expect(json_response['error']).to eq('Input is required')
        end
      end

      context 'when AI service returns error' do
        let(:input) { 'Create a goal' }
        let(:error_response) do
          {
            intent: :error,
            response: { error: 'OpenAI API error' },
            context_used: false
          }
        end

        before do
          allow(mock_ai_service).to receive(:process).and_return(error_response)
        end

        it 'returns internal server error' do
          post '/api/v1/ai', params: { input: input }, headers: headers

          expect(response).to have_http_status(:internal_server_error)
          json_response = JSON.parse(response.body)
          expect(json_response['error']).to eq('OpenAI API error')
        end
      end

      context 'when AI service raises an exception' do
        let(:input) { 'Create a goal' }

        before do
          allow(mock_ai_service).to receive(:process).and_raise(StandardError, 'Unexpected error')
        end

        it 'returns internal server error' do
          post '/api/v1/ai', params: { input: input }, headers: headers

          expect(response).to have_http_status(:internal_server_error)
          json_response = JSON.parse(response.body)
          expect(json_response['error']).to eq('An unexpected error occurred')
        end
      end
    end

    context 'when user is not authenticated' do
      context 'with missing user ID header' do
        it 'returns unauthorized error' do
          post '/api/v1/ai', params: { input: 'Create a goal' }

          expect(response).to have_http_status(:unauthorized)
          json_response = JSON.parse(response.body)
          expect(json_response['error']).to eq('Authentication required')
        end
      end

      context 'with invalid user ID' do
        let(:headers) { { 'X-User-ID' => '999999' } }

        it 'returns unauthorized error' do
          post '/api/v1/ai', params: { input: 'Create a goal' }, headers: headers

          expect(response).to have_http_status(:unauthorized)
          json_response = JSON.parse(response.body)
          expect(json_response['error']).to eq('Authentication required')
        end
      end
    end
  end
end
