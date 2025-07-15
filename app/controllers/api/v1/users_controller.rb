# frozen_string_literal: true

module Api
  module V1
    # Controller for user authentication operations
    class UsersController < ApplicationController
      def create
        user = User.new(user_params)

        if user.save
          render json: {
            user: user.as_json(except: :password_digest),
            profile: user.profile
          }, status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def show
        user = User.find_by(id: params[:id])
        if user
          render json: {
            user: user.as_json(except: :password_digest),
            profile: user.profile
          }
        else
          render json: { errors: 'User could not be found.' }, status: :not_found
        end
      end

      private

      def user_params
        params.require(:user).permit(:email, :password, :password_confirmation)
      end
    end
  end
end
