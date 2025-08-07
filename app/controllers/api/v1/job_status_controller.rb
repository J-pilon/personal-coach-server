# frozen_string_literal: true

module Api
  module V1
    class JobStatusController < ApplicationController
      before_action :authenticate_api_v1_user!

      def show
        job_id = params[:id]
        job_status = Sidekiq::Status.get_all(job_id)

        if job_status.empty?
          render json: { error: 'Job not found' }, status: :not_found
        else
          render json: build_job_status_response(job_id, job_status)
        end
      rescue StandardError => e
        Rails.logger.error "Job status error: #{e.message}"
        render json: { error: 'Failed to get job status' }, status: :internal_server_error
      end

      private

      def build_job_status_response(job_id, job_status)
        {
          job_id: job_id,
          status: job_status['status'] || 'unknown',
          progress: job_status['progress'] || 0,
          result: job_status['result']
        }
      end
    end
  end
end
