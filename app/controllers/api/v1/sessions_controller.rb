module Api
  module V1
    class SessionsController < Devise::SessionsController
      include ::RackSessionFixController
      respond_to :json

      def create
        Rails.logger.info "SessionsController#create called with params: #{params.inspect}"

        # Get user parameters
        user_params = sign_in_params
        return render json: { error: 'Invalid parameters' }, status: :bad_request unless user_params

        # Find and authenticate user
        user = User.find_by(email: user_params[:email])

        if user && user.valid_password?(user_params[:password])
          # Sign in the user - Devise will handle JWT token generation
          sign_in(user)

          # Return success response
          respond_with(user)
        else
          render json: { error: 'Invalid email or password' }, status: :unauthorized
        end
      end

      private

      def respond_with(current_user, _opts = {})
        render json: {
          status: {
            code: 200, message: 'Logged in successfully.',
            data: { user: UserSerializer.new(current_user).serializable_hash[:data][:attributes] }
          }
        }, status: :ok
      end

      def respond_to_on_destroy
        if request.headers['Authorization'].present?
          jwt_payload = JWT.decode(request.headers['Authorization'].split(' ').last, Rails.application.credentials.devise_jwt_secret_key!).first
          current_user = User.find(jwt_payload['sub'])
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
        user_params.permit(:email, :password) if user_params
      end
    end
  end
end
