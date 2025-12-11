# frozen_string_literal: true

module Api
  module V1
    class NotificationPreferencesController < ApplicationController
      before_action :authenticate_api_v1_user!

      def show
        render json: notification_preference_response
      end

      def update
        if current_notification_preference.update(notification_preference_params)
          render json: notification_preference_response
        else
          render json: {
            errors: current_notification_preference.errors.full_messages
          }, status: :unprocessable_content
        end
      end

      private

      def current_notification_preference
        current_api_v1_profile.notification_preference
      end

      def notification_preference_response
        {
          notification_preference: current_notification_preference.as_json(
            only: %i[push_enabled preferred_time timezone]
          )
        }
      end

      def notification_preference_params
        params.require(:notification_preference).permit(:push_enabled, :preferred_time, :timezone)
      end
    end
  end
end
