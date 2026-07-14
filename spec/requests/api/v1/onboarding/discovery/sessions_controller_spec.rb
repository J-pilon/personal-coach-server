# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Onboarding::Discovery::Sessions', type: :request do
  let!(:user) { create(:user) }
  let!(:profile) { user.profile }

  before { sign_in user }

  describe 'POST /api/v1/onboarding/discovery/sessions' do
    it 'creates a session and enqueues the first-question job' do
      job = instance_double(ActiveJob::Base, provider_job_id: 'job-abc')
      allow(OnboardingDiscoveryJob).to receive(:perform_later).and_return(job)

      expect { post api_v1_onboarding_discovery_sessions_path, as: :json }
        .to change(DiscoverySession, :count).by(1)
        .and change(AiRequest, :count).by(1)

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body).to include('session_id', 'ai_request_id', 'job_id', 'status')
      expect(body['job_id']).to eq('job-abc')
      expect(OnboardingDiscoveryJob).to have_received(:perform_later).with(
        hash_including(discovery_session_id: kind_of(Integer), ai_request_id: kind_of(Integer))
      )
    end
  end
end
