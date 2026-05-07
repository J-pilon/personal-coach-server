# frozen_string_literal: true

require_relative '../../concerns/rack_session_fix_controller'

module Api
  module V1
    class PasswordsController < Devise::PasswordsController
      include ::RackSessionFixController

      respond_to :json

      # POST /api/v1/password
      # Sends reset instructions. Always returns 200 to avoid leaking which
      # emails are registered.
      def create
        email = params.dig(:user, :email).to_s.strip.downcase
        User.send_reset_password_instructions(email: email) if email.present?

        render json: {
          status: { code: 200, message: 'If that email is registered, password reset instructions have been sent.' }
        }, status: :ok
      end

      # PUT /api/v1/password
      # Submits a new password using the token from the email. 422 on invalid
      # or expired token; specific error key lets the client distinguish.
      def update
        resource = User.reset_password_by_token(reset_password_params)

        if resource.errors.empty?
          render json: {
            status: { code: 200, message: 'Password has been reset successfully.' }
          }, status: :ok
        else
          render json: {
            status: {
              code: 422,
              message: resource.errors.full_messages.to_sentence,
              errors: resource.errors.as_json
            }
          }, status: :unprocessable_entity
        end
      end

      private

      def reset_password_params
        params.require(:user).permit(:reset_password_token, :password, :password_confirmation)
      end
    end
  end
end
