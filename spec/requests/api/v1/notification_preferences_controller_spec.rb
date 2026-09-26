# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::NotificationPreferences', type: :request do
  let!(:user) { create(:user) }
  let!(:profile) { user.profile }

  before { sign_in user }

  describe 'GET /api/v1/notification_preferences' do
    it 'returns the current notification preferences' do
      get api_v1_notification_preferences_path

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json['notification_preference']).to be_present
      expect(json['notification_preference']).to include('push_enabled', 'preferred_time')
    end
  end

  describe 'PATCH /api/v1/notification_preferences' do
    it 'updates push_enabled' do
      patch api_v1_notification_preferences_path,
            params: { notification_preference: { push_enabled: false } },
            as: :json

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json['notification_preference']['push_enabled']).to be false
    end

    it 'updates preferred_time' do
      patch api_v1_notification_preferences_path,
            params: { notification_preference: { preferred_time: '18:00' } },
            as: :json

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json['notification_preference']['preferred_time']).to include('18:00:00')
    end

    it 'returns a validation error with the standard envelope when save fails' do
      allow_any_instance_of(NotificationPreference).to receive(:update).and_return(false) # rubocop:disable RSpec/AnyInstance
      allow_any_instance_of(NotificationPreference).to receive(:errors).and_return( # rubocop:disable RSpec/AnyInstance
        instance_double(
          ActiveModel::Errors,
          full_messages: ['Push enabled is invalid'],
          to_hash: { push_enabled: ['is invalid'] },
          present?: true
        )
      )

      patch api_v1_notification_preferences_path,
            params: { notification_preference: { push_enabled: false } },
            as: :json

      expect(response).to have_http_status(:unprocessable_content)
      json = response.parsed_body
      expect(json['error']).to be_present
      expect(json['error']['code']).to eq('')
      expect(json['error']['message']).to eq('Push enabled is invalid')
      expect(json['error']['details']).to be_present
      expect(json['error']['details']['push_enabled']).to include('is invalid')
    end
  end
end
