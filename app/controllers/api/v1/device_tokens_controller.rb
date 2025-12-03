# frozen_string_literal: true

module Api
  module V1
    class DeviceTokensController < ApplicationController
      before_action :authenticate_api_v1_user!

      def create
        device_token = current_api_v1_profile.device_tokens.find_or_initialize_by(
          token: device_token_params[:token]
        )

        device_token.assign_attributes(
          platform: device_token_params[:platform],
          device_name: device_token_params[:device_name],
          app_version: device_token_params[:app_version],
          active: true,
          last_used_at: Time.current
        )

        if device_token.save
          render json: {
            message: 'Device registered',
            device_token: device_token.as_json(only: %i[id platform active])
          }, status: :ok
        else
          render json: {
            errors: device_token.errors.full_messages
          }, status: :unprocessable_content
        end
      end

      def destroy
        device_token = current_api_v1_profile.device_tokens.find_by(token: params[:token])
        device_token&.deactivate!

        render json: { message: 'Device unregistered' }, status: :ok
      end

      private

      def device_token_params
        params.require(:device_token).permit(:token, :platform, :device_name, :app_version)
      end
    end
  end
end
