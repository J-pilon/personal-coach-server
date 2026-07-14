# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Onboarding::Discovery::Messages', type: :request do
  let!(:user) { create(:user) }
  let!(:profile) { user.profile }
  let!(:session) { create(:discovery_session, profile: profile) }

  before do
    sign_in user
    job = instance_double(ActiveJob::Base, provider_job_id: 'job-abc')
    allow(OnboardingDiscoveryJob).to receive(:perform_later).and_return(job)
  end

  describe 'POST /api/v1/onboarding/discovery/messages' do
    it 'appends the user message and enqueues the next-turn job' do
      expect do
        post api_v1_onboarding_discovery_messages_path,
             params: { session_id: session.id, text: 'I want to run a 10k.' },
             as: :json
      end.to change(AiRequest, :count).by(1)

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body).to include('session_id', 'ai_request_id', 'job_id', 'force_draft', 'turn_count')
      expect(body['force_draft']).to be(false)

      session.reload
      expect(session.messages.last).to include('role' => 'user', 'text' => 'I want to run a 10k.')
    end

    it 'sets force_draft when the turn cap is reached (turn 7)' do
      session.update!(turn_count: DiscoverySession::MAX_TURNS - 1)

      post api_v1_onboarding_discovery_messages_path,
           params: { session_id: session.id, text: 'ok proceed' },
           as: :json

      expect(response).to have_http_status(:created)
      expect(response.parsed_body['force_draft']).to be(true)
      expect(OnboardingDiscoveryJob).to have_received(:perform_later).with(
        hash_including(force_draft: true)
      )
    end
  end
end
