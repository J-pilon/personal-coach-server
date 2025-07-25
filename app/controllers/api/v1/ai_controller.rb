# frozen_string_literal: true

module Api
  module V1
    class AiController < ApplicationController
      before_action :authenticate_user!

      def create
        input = params[:input]

        if input.blank?
          render json: { error: 'Input is required' }, status: :bad_request
          return
        end

        result = Ai::AiService.new(current_user.profile).process(input)

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
    end
  end
end
