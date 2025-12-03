# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Notifications::Delivery::PushService do
  subject(:service) do
    described_class.new(
      device_token: device_token,
      notification: notification,
      http_client: mock_http_client
    )
  end

  let(:device_token) { create(:device_token) }
  let(:notification) { create(:notification, profile: device_token.profile) }

  # Mock response object
  let(:mock_response) { instance_double(Faraday::Response, success?: true, body: {}) }

  # Mock HTTP client instance
  let(:mock_client_instance) { instance_double(HttpClientService, post: mock_response) }

  # Mock HTTP client class
  let(:mock_http_client) do
    class_double(HttpClientService, new: mock_client_instance)
  end

  describe '#deliver' do
    context 'when request succeeds' do
      it 'updates notification status to sent' do
        service.deliver

        expect(notification.reload.status).to eq('sent')
        expect(notification.sent_at).to be_present
      end

      it 'touches device token last_used_at' do
        expect { service.deliver }.to(change { device_token.reload.last_used_at })
      end

      it 'sends correct payload to Expo API' do
        expected_payload = {
          to: device_token.token,
          title: notification.title,
          body: notification.body,
          data: notification.data,
          sound: 'default',
          channelId: 'default'
        }

        service.deliver

        expect(mock_client_instance).to have_received(:post).with(payload: expected_payload)
      end
    end

    context 'when request fails' do
      let(:mock_response) { instance_double(Faraday::Response, success?: false, body: 'Connection refused') }

      it 'updates notification status to failed' do
        service.deliver

        expect(notification.reload.status).to eq('failed')
        expect(notification.error_message).to eq('Connection refused')
      end
    end

    context 'when Expo returns DeviceNotRegistered error' do
      let(:error_body) do
        { 'data' => { 'status' => 'error', 'message' => 'DeviceNotRegistered' } }
      end
      let(:mock_response) { instance_double(Faraday::Response, success?: true, body: error_body) }

      it 'deactivates the device token' do
        expect { service.deliver }.to change { device_token.reload.active }.from(true).to(false)
      end

      it 'still marks notification as sent' do
        service.deliver

        expect(notification.reload.status).to eq('sent')
      end
    end

    context 'when Expo returns success without errors' do
      let(:success_body) { { 'data' => { 'status' => 'ok' } } }
      let(:mock_response) { instance_double(Faraday::Response, success?: true, body: success_body) }

      it 'does not deactivate the device token' do
        expect { service.deliver }.not_to(change { device_token.reload.active })
      end
    end
  end
end
