# frozen_string_literal: true

module Api
  module V1
    class JobStatusController < ApplicationController
      before_action :authenticate_api_v1_user!

      def show
        job_id = params[:id]
        job_status = get_job_status(job_id)

        Rails.logger.info 'Jobs Status Controller: ' \
                          "job_status=#{job_status}, job_id=#{job_id}"

        if job_status.blank?
          render json: { error: 'Job not found' }, status: :not_found
        else
          render json: build_job_status_response(job_id, job_status)
        end
      rescue StandardError => e
        log_job_status_error(e)
        render json: { error: 'Failed to get job status' }, status: :internal_server_error
      end

      private

      def get_job_status(job_id)
        JobStatusService.get_status(job_id)
      end

      def build_job_status_response(job_id, status_data)
        JobStatusService.build_status_response(job_id, status_data)
      end

      def log_job_status_error(error)
        Rails.logger.error "Job status error: #{error.message}"
        Rails.logger.error "Backtrace: #{error.backtrace&.first(5)&.join("\n")}"
      end
    end
  end
end
