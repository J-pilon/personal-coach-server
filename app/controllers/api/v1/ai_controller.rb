# frozen_string_literal: true

module Api
  module V1
    class AiController < ApplicationController
      before_action :authenticate_api_v1_user!

      def proxy
        input = params[:input]
        timeframe = params[:timeframe]
        intent = params[:intent]
        user_provided_key = params[:user_provided_key]

        if input.blank?
          render_standard_error(message: 'Input is required', status: :bad_request)
          return
        end

        result = Ai::RateLimiter.check_and_record(current_api_v1_profile, user_provided_key)

        if result[:error].present?
          render_standard_error(
            message: result[:error],
            status: :too_many_requests,
            details: { reason: result[:reason] }
          )
          return
        end

        job = AiServiceJob.perform_later(
          profile_id: current_api_v1_profile.id,
          input: input,
          timeframe: timeframe,
          user_provided_key: user_provided_key,
          intent: intent
        )

        render json: {
          message: 'AI request queued for processing',
          job_id: job.provider_job_id,
          status: 'queued',
          usage_info: result
        }
      end

      def usage
        user_provided_key = params[:user_provided_key]
        result = Ai::RateLimiter.new(current_api_v1_profile, user_provided_key).usage_info
        render json: { usage_info: result }
      end

      def suggested_tasks
        profile_id = params[:profile_id] || current_api_v1_profile.id
        user_provided_key = params[:user_provided_key]
        profile = Profile.find(profile_id)

        result = Ai::RateLimiter.check_and_record(profile, user_provided_key)

        if result[:error].present?
          render_standard_error(
            message: result[:error],
            status: :too_many_requests,
            details: { reason: result[:reason] }
          )
          return
        end

        job = TaskSuggestionJob.perform_later(
          profile_id: profile.id,
          user_provided_key: user_provided_key
        )

        render json: {
          message: 'Task suggestions queued for processing',
          job_id: job.provider_job_id,
          status: 'queued',
          usage_info: result
        }
      rescue ActiveRecord::RecordNotFound
        render_standard_error(message: 'Profile not found', status: :not_found)
      rescue StandardError => e
        Rails.logger.error "Task suggestions error: #{e.message}"
        render_standard_error(message: 'Failed to generate task suggestions', status: :internal_server_error)
      end
    end
  end
end
