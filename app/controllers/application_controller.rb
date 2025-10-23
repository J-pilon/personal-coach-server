# frozen_string_literal: true

class ApplicationController < ActionController::API
  private

  def current_api_v1_profile
    current_api_v1_user.profile
  end

  # Helper method to get job status using the JobStatusService
  def get_job_status(job_id)
    JobStatusService.get_status(job_id)
  end

  # Helper method to build job status response
  def build_job_status_response(job_id, status_data)
    JobStatusService.build_status_response(job_id, status_data)
  end
end
