require_relative '../../concerns/rack_sessions_fix'

module Api
  module V1
    # API controller for user registration using Devise
    class RegistrationsController < Devise::RegistrationsController
      include ::RackSessionFixController

      respond_to :json

      private

      def respond_with(current_user, _opts = {})
        if resource.persisted?
          render json: {
            status: { code: 200, message: 'Signed up successfully.' },
            data: UserSerializer.new(current_user).serializable_hash[:data][:attributes]
          }
        else
          render json: {
            status: { message: "User couldn't be created successfully. #{resource.errors.full_messages.to_sentence}" }
          }, status: :unprocessable_entity
        end
      end

      def sign_up_params
        params.require(:user).permit(:email, :password, :password_confirmation)
      rescue ActionController::ParameterMissing
        nil
      end
    end
  end
end
