# frozen_string_literal: true

module Api
  module V1
    module Onboarding
      class HabitsController < ApplicationController
        before_action :authenticate_api_v1_user!

        def suggest
          smart_goal = current_api_v1_profile.smart_goals.find_by(id: params[:smart_goal_id])
          return render json: { error: 'SmartGoal not found' }, status: :not_found unless smart_goal

          exclude = Array(params[:exclude])
          position = params[:position].presence&.to_i

          if position && !(1..3).cover?(position)
            return render json: { errors: ['position must be 1..3'] }, status: :unprocessable_content
          end

          ai_request = AiRequest.create!(
            profile: current_api_v1_profile,
            prompt: '[pending onboarding_habit_suggestion prompt]',
            job_type: 'onboarding_habit_suggestion',
            status: 'pending'
          )

          job = OnboardingHabitSuggestionJob.perform_later(
            smart_goal_id: smart_goal.id,
            ai_request_id: ai_request.id,
            exclude: exclude,
            position: position
          )

          render json: {
            ai_request_id: ai_request.id,
            job_id: job.provider_job_id,
            status: 'queued'
          }, status: :accepted
        end
      end
    end
  end
end
