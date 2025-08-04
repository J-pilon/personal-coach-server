# frozen_string_literal: true

module Api
  module V1
    class ProfilesController < ApplicationController
      before_action :authenticate_api_v1_user!

      def show
        user = current_api_v1_user
        if user
          profile = user.profile
          if profile.id.to_s == params[:id]
            render json: profile
          else
            render json: { errors: 'Profile could not be found.' }, status: :not_found
          end
        else
          render json: { errors: 'Profile could not be found.' }, status: :not_found
        end
      end

      def update
        user = current_api_v1_user
        if user
          profile = user.profile
          if profile.id.to_s == params[:id]
            if profile.update(profile_params)
              render json: profile
            else
              render json: { errors: profile.errors.full_messages }, status: :unprocessable_entity
            end
          else
            render json: { errors: 'Profile could not be found.' }, status: :not_found
          end
        else
          render json: { errors: 'Profile could not be found.' }, status: :not_found
        end
      end

      def complete_onboarding
        user = current_api_v1_user
        if user
          profile = user.profile
          if profile.id.to_s == params[:id]
            profile.complete_onboarding!
            render json: profile
          else
            render json: { errors: 'Profile could not be found.' }, status: :not_found
          end
        else
          render json: { errors: 'Profile could not be found.' }, status: :not_found
        end
      end

      private

      def profile_params
        params.require(:profile).permit(
          :first_name, :last_name, :work_role, :education,
          :desires, :limiting_beliefs, :onboarding_status
        )
      end
    end
  end
end
