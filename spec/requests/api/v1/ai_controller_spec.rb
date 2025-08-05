# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::AiController, type: :request do
  let(:user) { create(:user) }
  let(:profile) { create(:profile, user: user) }

  before do
    # Ensure user has a profile
    user.profile || create(:profile, user: user)
    # Sign in the user using Devise test helpers
    sign_in user
  end

  describe 'POST /api/v1/ai' do
    context 'with valid input' do
      it 'processes AI request successfully' do
        allow_any_instance_of(Ai::AiService).to receive(:process).and_return({
                                                                               intent: :smart_goal,
                                                                               response: { specific: 'Test goal' },
                                                                               context_used: true,
                                                                               request_id: 1
                                                                             })

        post '/api/v1/ai', params: { input: 'Create a goal' }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['intent']).to eq('smart_goal')
      end
    end

    context 'with blank input' do
      it 'returns bad request error' do
        post '/api/v1/ai', params: { input: '' }

        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Input is required')
      end
    end
  end

  describe 'POST /api/v1/ai/suggested_tasks' do
    let!(:task) { create(:task, profile: profile, title: 'Existing task', completed: false) }
    let!(:smart_goal) { create(:smart_goal, profile: profile, title: 'Test Goal') }

    context 'with valid profile' do
      it 'returns AI-generated task suggestions' do
        mock_suggestions = [
          {
            title: 'Update portfolio README',
            description: 'Clarify project goals',
            goal_id: smart_goal.id.to_s,
            time_estimate_minutes: 30
          },
          {
            title: 'Review weekly metrics',
            description: 'Track progress on goals',
            goal_id: nil,
            time_estimate_minutes: 45
          },
          {
            title: 'Plan next sprint',
            description: 'Prepare for upcoming work',
            goal_id: smart_goal.id.to_s,
            time_estimate_minutes: 60
          }
        ]

        allow_any_instance_of(Ai::TaskSuggester).to receive(:generate_suggestions).and_return(mock_suggestions)

        post '/api/v1/ai/suggested_tasks', params: { profile_id: profile.id }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response).to be_an(Array)
        expect(json_response.length).to eq(3)
        expect(json_response.first['title']).to eq('Update portfolio README')
        expect(json_response.first['time_estimate_minutes']).to eq(30)
      end
    end

    context 'with invalid profile_id' do
      it 'returns not found error' do
        post '/api/v1/ai/suggested_tasks', params: { profile_id: 99_999 }

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Profile not found')
      end
    end

    context 'when AI service fails' do
      it 'returns internal server error' do
        allow_any_instance_of(Ai::TaskSuggester).to receive(:generate_suggestions).and_raise(StandardError,
                                                                                             'AI service error')

        post '/api/v1/ai/suggested_tasks', params: { profile_id: profile.id }

        expect(response).to have_http_status(:internal_server_error)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Failed to generate task suggestions')
      end
    end
  end
end
