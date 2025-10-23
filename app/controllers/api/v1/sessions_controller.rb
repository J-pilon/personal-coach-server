# frozen_string_literal: true

require_relative '../../concerns/rack_session_fix_controller'

module Api
  module V1
    class SessionsController < Devise::SessionsController
      include ::RackSessionFixController

      respond_to :json

      def create
        Rails.logger.info "SessionsController#create called with params: #{params.inspect}"

        user_params = sign_in_params
        Rails.logger.info "User params: #{user_params.inspect}"

        unless user_params
          Rails.logger.info 'No user params found, returning unauthorized'
          return render json: {
            status: {
              code: 401,
              message: 'Invalid parameters'
            }
          }, status: :unauthorized
        end

        # Find and authenticate user
        user = User.find_by(email: user_params[:email])
        Rails.logger.info "Found user: #{user.inspect}"

        if user&.valid_password?(user_params[:password])
          Rails.logger.info 'User authenticated successfully'
          sign_in(user)

          # Return success response with JWT token
          respond_with(user)
        else
          Rails.logger.info "Authentication failed - user: #{user.inspect}, " \
                            "password_valid: #{user&.valid_password?(user_params[:password])}"
          render json: {
            status: {
              code: 401,
              message: 'Invalid email or password.'
            }
          }, status: :unauthorized
        end
      end

      def destroy
        respond_to_on_destroy
      end

      private

      def respond_with(current_user, _opts = {})
        render json: {
          status: { code: 200, message: 'Logged in successfully.' },
          data: {
            user: UserSerializer.new(current_user).serializable_hash[:data][:attributes],
            profile: current_user.profile.as_json(only: %i[id first_name last_name work_role education
                                                           desires limiting_beliefs onboarding_status
                                                           onboarding_completed_at user_id created_at updated_at])
          }
        }, status: :ok
      end

      def respond_to_on_destroy
        if request.headers['Authorization'].present?
          auth_header = request.headers['Authorization']

          # Check if Authorization header has the correct format
          unless auth_header.start_with?('Bearer ')
            return render json: {
              status: 401,
              message: "Couldn't find an active session."
            }, status: :unauthorized
          end

          begin
            token = auth_header.split.last
            jwt_payload = JWT.decode(token, Rails.application.credentials.devise_jwt_secret_key!).first

            # Handle both scoped and unscoped JWT tokens
            user_id = jwt_payload['sub'] || jwt_payload['user_id']
            current_user = User.find(user_id) if user_id
          rescue JWT::DecodeError, JWT::ExpiredSignature, ActiveRecord::RecordNotFound
            current_user = nil
          end
        end

        if current_user
          render json: {
            status: 200,
            message: 'Logged out successfully.'
          }, status: :ok
        else
          render json: {
            status: 401,
            message: "Couldn't find an active session."
          }, status: :unauthorized
        end
      end

      def sign_in_params
        # Handle both formats: direct user params or nested under session
        user_params = params[:user] || params.dig(:session, :user)
        user_params&.permit(:email, :password)
      end
    end
  end
end
