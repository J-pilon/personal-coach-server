# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'DeviceTokens', type: :request do
  let(:user) { create(:user) }
  let(:profile) { create(:profile, user: user) }

  before { sign_in user }

  describe 'POST /api/v1/device_tokens' do
    let(:valid_params) do
      {
        device_token: {
          token: 'ExponentPushToken[abc123]',
          platform: 'ios',
          device_name: 'iPhone 15',
          app_version: '1.2.0'
        }
      }
    end

    it 'registers a new device token' do
      expect do
        post '/api/v1/device_tokens', params: valid_params
      end.to change(DeviceToken, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['message']).to eq('Device registered')
    end

    it 'updates existing token if already registered' do
      create(:device_token, profile: profile, token: 'ExponentPushToken[abc123]', app_version: '1.0.0')

      expect do
        post '/api/v1/device_tokens', params: valid_params
      end.not_to change(DeviceToken, :count)

      expect(response).to have_http_status(:ok)
      expect(DeviceToken.last.app_version).to eq('1.2.0')
    end

    it 'returns errors for invalid platform' do
      invalid_params = valid_params.deep_dup
      invalid_params[:device_token][:platform] = 'invalid'

      post '/api/v1/device_tokens', params: invalid_params

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body['errors']).to include('Platform is not included in the list')
    end
  end

  describe 'DELETE /api/v1/device_tokens/:id' do
    let!(:device_token) { create(:device_token, profile: profile) }

    it 'deactivates the device token' do
      delete "/api/v1/device_tokens/#{device_token.id}", params: { token: device_token.token }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['message']).to eq('Device unregistered')
      expect(device_token.reload.active).to be false
    end

    it 'returns success even if token not found' do
      delete '/api/v1/device_tokens/0', params: { token: 'nonexistent' }

      expect(response).to have_http_status(:ok)
    end
  end

  context 'when not authenticated' do
    before { sign_out user }

    it 'returns unauthorized for create' do
      post '/api/v1/device_tokens', params: { device_token: { token: 'test', platform: 'ios' } }
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns unauthorized for destroy' do
      delete '/api/v1/device_tokens/1', params: { token: 'test' }
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
