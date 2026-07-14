# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Onboarding::Habits', type: :request do
  let!(:user) { create(:user) }
  let!(:profile) { user.profile }
  let!(:smart_goal) { create(:smart_goal, profile: profile) }

  before do
    sign_in user
    job = instance_double(ActiveJob::Base, provider_job_id: 'job-xyz')
    allow(OnboardingHabitSuggestionJob).to receive(:perform_later).and_return(job)
  end

  describe 'POST /api/v1/onboarding/habits/suggest' do
    it 'enqueues a suggestion job for 3 habits' do
      expect do
        post api_v1_onboarding_habits_suggest_path, params: { smart_goal_id: smart_goal.id }, as: :json
      end.to change(AiRequest, :count).by(1)

      expect(response).to have_http_status(:accepted)
      expect(OnboardingHabitSuggestionJob).to have_received(:perform_later).with(
        hash_including(smart_goal_id: smart_goal.id, position: nil, exclude: [])
      )
    end

    it 'accepts position and exclude for a single replacement' do
      post api_v1_onboarding_habits_suggest_path,
           params: { smart_goal_id: smart_goal.id, position: 2, exclude: ['Old habit'] },
           as: :json

      expect(response).to have_http_status(:accepted)
      expect(OnboardingHabitSuggestionJob).to have_received(:perform_later).with(
        hash_including(smart_goal_id: smart_goal.id, position: 2, exclude: ['Old habit'])
      )
    end

    it 'rejects out-of-range position' do
      post api_v1_onboarding_habits_suggest_path,
           params: { smart_goal_id: smart_goal.id, position: 4 },
           as: :json

      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'returns not found for another user\'s goal' do
      other_goal = create(:smart_goal, profile: create(:user).profile)

      post api_v1_onboarding_habits_suggest_path, params: { smart_goal_id: other_goal.id }, as: :json

      expect(response).to have_http_status(:not_found)
    end
  end
end
