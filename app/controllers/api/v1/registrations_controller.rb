require_relative '../../concerns/rack_session_fix_controller'

module Api
  module V1
    class RegistrationsController < Devise::RegistrationsController
      include ::RackSessionFixController

      respond_to :json

      private

      # rubocop:disable Metrics/MethodLength
      def respond_with(current_user, _opts = {})
        if resource.persisted?
          render json: {
            status: { code: 200, message: 'Signed up successfully.' },
            data: {
              user: UserSerializer.new(current_user).serializable_hash[:data][:attributes],
              profile: current_user.profile.as_json(only: [:id, :first_name, :last_name, :work_role, :education, :desires, :limiting_beliefs, :onboarding_status, :onboarding_completed_at, :user_id, :created_at, :updated_at])
            }
          }, status: :ok
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
