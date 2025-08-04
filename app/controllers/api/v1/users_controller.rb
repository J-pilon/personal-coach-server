# frozen_string_literal: true

module Api
  module V1
    # Controller for user authentication operations
    class UsersController < ApplicationController
      before_action :authenticate_api_v1_user!, only: [:me]

      def me
        render json: {
          user: current_api_v1_user.as_json(except: :password_digest),
          profile: current_api_v1_user.profile
        }
      end
    end
  end
end
