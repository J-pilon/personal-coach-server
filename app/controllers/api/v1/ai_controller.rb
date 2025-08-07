# frozen_string_literal: true

module Api
  module V1
    class AiController < ApplicationController
      before_action :authenticate_api_v1_user!

      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/MethodLength
      def create
        input = params[:input]

        if input.blank?
          render json: { error: 'Input is required' }, status: :bad_request
          return
        end

        # Enqueue the job for background processing
        job = AiServiceJob.perform_later(current_api_v1_profile.id, input)

        render json: {
          message: 'AI request queued for processing',
          job_id: job.provider_job_id,
          status: 'queued'
        }
      rescue StandardError => e
        Rails.logger.error "AI Controller error: #{e.message}"
        render json: { error: 'An unexpected error occurred' }, status: :internal_server_error
      end

      def proxy
        input = params[:input]
        user_provided_key = params[:user_provided_key]

        if input.blank?
          render json: { error: 'Input is required' }, status: :bad_request
          return
        end

        # Initialize rate limiter
        rate_limiter = Ai::RateLimiter.new(current_api_v1_profile, user_provided_key)

        # Check rate limits if no user key provided
        if user_provided_key.blank?
          limit_check = rate_limiter.check_limit
          unless limit_check[:allowed]
            render json: {
              error: limit_check[:message],
              reason: limit_check[:reason]
            }, status: :too_many_requests
            return
          end
        end

        # Enqueue the job for background processing
        job = AiServiceJob.perform_later(current_api_v1_profile.id, input, user_provided_key)

        # Record the request for rate limiting
        rate_limiter.record_request

        render json: {
          message: 'AI request queued for processing',
          job_id: job.provider_job_id,
          status: 'queued',
          usage_info: rate_limiter.usage_info
        }
      end

      def usage
        user_provided_key = params[:user_provided_key]
        rate_limiter = Ai::RateLimiter.new(current_api_v1_profile, user_provided_key)
        render json: { usage_info: rate_limiter.usage_info }
      end

      def suggested_tasks
        profile_id = params[:profile_id] || current_api_v1_profile.id
        user_provided_key = params[:user_provided_key]
        profile = Profile.find(profile_id)

        # Initialize rate limiter
        rate_limiter = Ai::RateLimiter.new(profile, user_provided_key)

        # Check rate limits if no user key provided
        if user_provided_key.blank?
          limit_check = rate_limiter.check_limit
          unless limit_check[:allowed]
            render json: {
              error: limit_check[:message],
              reason: limit_check[:reason]
            }, status: :too_many_requests
            return
          end
        end

        # Enqueue the job for background processing
        job = TaskSuggestionJob.perform_later(profile.id, user_provided_key)

        # Record the request for rate limiting
        rate_limiter.record_request

        render json: {
          message: 'Task suggestions queued for processing',
          job_id: job.provider_job_id,
          status: 'queued',
          usage_info: rate_limiter.usage_info
        }
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Profile not found' }, status: :not_found
      rescue StandardError => e
        Rails.logger.error "Task suggestions error: #{e.message}"
        render json: { error: 'Failed to generate task suggestions' }, status: :internal_server_error
      end
    end
  end
end
