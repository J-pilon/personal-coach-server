# frozen_string_literal: true

module Api
  module V1
    class ProfilesController < ApplicationController
      before_action :authenticate_api_v1_user!

      def show
        if current_api_v1_profile.id.to_s == params[:id]
          render json: current_api_v1_profile
        else
          render json: { errors: 'Profile could not be found.' }, status: :not_found
        end
      end

      def update
        if current_api_v1_profile.id.to_s == params[:id]
          if current_api_v1_profile.update(profile_params)
            render json: current_api_v1_profile
          else
            render json: { errors: current_api_v1_profile.errors.full_messages }, status: :unprocessable_entity
          end
        else
          render json: { errors: 'Profile could not be found.' }, status: :not_found
        end
      end

      def complete_onboarding
        if current_api_v1_profile.id.to_s == params[:id]
          current_api_v1_profile.complete_onboarding!
          render json: current_api_v1_profile
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
