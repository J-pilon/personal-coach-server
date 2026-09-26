# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::DeviceTokens', type: :request do
  let!(:user) { create(:user) }
  let!(:profile) { user.profile }

  before { sign_in user }

  def device_token_params(overrides = {})
    {
      device_token: {
        token: 'ExponentPushToken[test-abc-123]',
        platform: 'ios',
        device_name: 'iPhone 15',
        app_version: '1.0.0'
      }.merge(overrides)
    }
  end

  describe 'POST /api/v1/device_tokens' do
    it 'registers a new device token' do
      expect { post api_v1_device_tokens_path, params: device_token_params, as: :json }
        .to change(DeviceToken, :count).by(1)

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json['message']).to eq('Device registered')
      expect(json['device_token']).to be_present
    end

    it 'is idempotent for an existing token (updates, does not duplicate)' do
      create(:device_token, profile: profile, token: 'ExponentPushToken[test-abc-123]', platform: 'ios')

      expect { post api_v1_device_tokens_path, params: device_token_params, as: :json }
        .not_to change(DeviceToken, :count)

      expect(response).to have_http_status(:ok)
    end

    it 'returns a validation error for an invalid platform' do
      post api_v1_device_tokens_path,
           params: device_token_params(platform: 'fax_machine'),
           as: :json

      expect(response).to have_http_status(:unprocessable_content)
      json = response.parsed_body
      expect(json['error']).to be_present
      expect(json['error']['code']).to eq('')
      expect(json['error']['message']).to be_present
      expect(json['error']['details']).to be_present
      expect(json['error']['details']['platform']).to be_present
    end
  end

  describe 'DELETE /api/v1/device_tokens/:id' do
    it 'unregisters a device token' do
      token = create(:device_token, profile: profile)

      delete api_v1_device_token_path(token), params: { token: token.token }, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['message']).to eq('Device unregistered')
      expect(token.reload.active).to be false
    end

    it 'responds ok even when token is not found (idempotent)' do
      delete api_v1_device_token_path(0), params: { token: 'nonexistent-token' }, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['message']).to eq('Device unregistered')
    end
  end
end
