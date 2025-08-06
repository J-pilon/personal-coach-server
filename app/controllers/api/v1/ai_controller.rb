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

        result = Ai::AiService.new(current_api_v1_profile).process(input)

        if result[:intent] == :error
          render json: { error: result[:response][:error] }, status: :internal_server_error
        else
          render json: {
            intent: result[:intent],
            response: result[:response],
            context_used: result[:context_used],
            request_id: result[:request_id]
          }
        end
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

        # Process the AI request
        begin
          result = Ai::AiService.new(current_api_v1_profile, user_provided_key).process(input)

          # Record the request for rate limiting
          rate_limiter.record_request

          if result[:intent] == :error
            render json: { error: result[:response][:error] }, status: :internal_server_error
          else
            render json: {
              intent: result[:intent],
              response: result[:response],
              context_used: result[:context_used],
              request_id: result[:request_id],
              usage_info: rate_limiter.usage_info
            }
          end
        rescue StandardError => e
          Rails.logger.error "AI Proxy error: #{e.message}"
          render json: { error: 'An unexpected error occurred' }, status: :internal_server_error
        end
      end

      def usage
        rate_limiter = Ai::RateLimiter.new(current_api_v1_profile)
        render json: { usage_info: rate_limiter.usage_info }
      end

      def suggested_tasks
        profile_id = params[:profile_id] || current_api_v1_profile.id
        profile = Profile.find(profile_id)

        suggestions = Ai::TaskSuggester.new(profile).generate_suggestions

        render json: suggestions
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Profile not found' }, status: :not_found
      rescue StandardError => e
        Rails.logger.error "Task suggestions error: #{e.message}"
        render json: { error: 'Failed to generate task suggestions' }, status: :internal_server_error
      end
    end
  end
end
