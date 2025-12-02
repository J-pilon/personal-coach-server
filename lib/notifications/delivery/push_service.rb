# frozen_string_literal: true

module Notifications
  module Delivery
    class PushService
      EXPO_PUSH_URL = 'https://exp.host/--/api/v2/push/send'

      def initialize(device_token:, notification:, http_client: nil)
        @device_token = device_token
        @notification = notification
        @http_client = http_client || default_http_client
      end

      def deliver
        response = send_request

        if response.success?
          handle_success(response)
        else
          handle_failure(response)
        end
      end

      private

      def send_request
        @http_client.new(EXPO_PUSH_URL).post(payload: payload)
      end

      def payload
        {
          to: @device_token.token,
          title: @notification.title,
          body: @notification.body,
          data: @notification.data,
          sound: 'default',
          channelId: 'default'
        }
      end

      def handle_success(response)
        @notification.update!(status: 'sent', sent_at: Time.current)
        @device_token.touch_last_used!

        check_expo_errors(response.body)
      end

      def handle_failure(response)
        @notification.update!(
          status: 'failed',
          error_message: response.body.to_s
        )
      end

      def check_expo_errors(body)
        return unless body.is_a?(Hash) && body['data']

        error = body.dig('data', 'status')
        return unless error == 'error'

        detail = body.dig('data', 'message')
        return unless detail&.include?('DeviceNotRegistered')

        @device_token.deactivate!
      end

      def default_http_client
        HttpClientService
      end
    end
  end
end
