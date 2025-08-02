require 'rails_helper'

RSpec.describe 'Api::V1::Profiles', type: :request do
  let!(:user) { create(:user) }
  let!(:profile) { user.profile }

  describe 'GET /api/v1/profiles/:id' do
    context 'when profile exists' do
      it 'returns the profile data' do
        get api_v1_profile_path(profile)

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)

        expect(json_response['id']).to eq(profile.id)
        expect(json_response['user_id']).to eq(user.id)
        expect(json_response['first_name']).to eq(profile.first_name)
        expect(json_response['last_name']).to eq(profile.last_name)
        expect(json_response['onboarding_status']).to eq(profile.onboarding_status)
      end
    end

    context 'when profile does not exist' do
      it 'returns not found status' do
        get api_v1_profile_path(999_999)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'PATCH /api/v1/profiles/:id' do
    context 'with valid parameters' do
      let(:valid_params) do
        {
          profile: {
            first_name: 'John',
            last_name: 'Doe',
            work_role: 'Software Engineer',
            education: 'Bachelor of Science',
            desires: 'I want to become a senior developer',
            limiting_beliefs: 'I am not good enough',
            onboarding_status: 'complete'
          }
        }
      end

      it 'updates the profile' do
        patch api_v1_profile_path(profile), params: valid_params

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)

        expect(json_response['first_name']).to eq('John')
        expect(json_response['last_name']).to eq('Doe')
        expect(json_response['work_role']).to eq('Software Engineer')
        expect(json_response['education']).to eq('Bachelor of Science')
        expect(json_response['desires']).to eq('I want to become a senior developer')
        expect(json_response['limiting_beliefs']).to eq('I am not good enough')
        expect(json_response['onboarding_status']).to eq('complete')
      end

      it 'persists the changes to the database' do
        patch api_v1_profile_path(profile), params: valid_params

        profile.reload
        expect(profile.first_name).to eq('John')
        expect(profile.last_name).to eq('Doe')
        expect(profile.work_role).to eq('Software Engineer')
      end
    end

    context 'with partial parameters' do
      let(:partial_params) do
        {
          profile: {
            first_name: 'Jane'
          }
        }
      end

      it 'updates only the provided fields' do
        original_last_name = profile.last_name

        patch api_v1_profile_path(profile), params: partial_params

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)

        expect(json_response['first_name']).to eq('Jane')
        expect(json_response['last_name']).to eq(original_last_name)
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) do
        {
          profile: {
            onboarding_status: 'invalid_status'
          }
        }
      end

      it 'returns unprocessable entity status' do
        patch api_v1_profile_path(profile), params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns error messages' do
        patch api_v1_profile_path(profile), params: invalid_params
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to include('Onboarding status is not included in the list')
      end

      it 'does not update the profile' do
        original_status = profile.onboarding_status
        patch api_v1_profile_path(profile), params: invalid_params

        profile.reload
        expect(profile.onboarding_status).to eq(original_status)
      end
    end

    context 'when profile does not exist' do
      it 'returns not found status' do
        patch api_v1_profile_path(999_999), params: { profile: { first_name: 'John' } }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'PATCH /api/v1/profiles/:id/complete_onboarding' do
    context 'when onboarding is incomplete' do
      before do
        profile.update!(onboarding_status: 'incomplete')
      end

      it 'completes the onboarding' do
        patch complete_onboarding_api_v1_profile_path(profile)

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)

        expect(json_response['onboarding_status']).to eq('complete')
        expect(json_response['onboarding_completed_at']).to be_present
      end

      it 'persists the onboarding completion' do
        patch complete_onboarding_api_v1_profile_path(profile)

        profile.reload
        expect(profile.onboarding_status).to eq('complete')
        expect(profile.onboarding_completed_at).to be_present
      end
    end

    context 'when onboarding is already complete' do
      before do
        profile.update!(
          onboarding_status: 'complete',
          onboarding_completed_at: 1.day.ago
        )
      end

      it 'still returns success' do
        patch complete_onboarding_api_v1_profile_path(profile)

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)

        expect(json_response['onboarding_status']).to eq('complete')
      end

      it 'updates the completion timestamp' do
        original_timestamp = profile.onboarding_completed_at

        patch complete_onboarding_api_v1_profile_path(profile)

        profile.reload
        expect(profile.onboarding_completed_at).to be > original_timestamp
      end
    end

    context 'when profile does not exist' do
      it 'returns not found status' do
        patch complete_onboarding_api_v1_profile_path(999_999)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
