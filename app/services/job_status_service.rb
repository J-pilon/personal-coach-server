# frozen_string_literal: true

# Service class for handling Sidekiq job status retrieval
class JobStatusService
  def self.get_status(job_id)
    return nil unless job_id

    begin
      status_data = Sidekiq::Status.get_all(job_id)
      Rails.logger.info "Retrieved job status for #{job_id}: #{status_data}"
      status_data
    rescue StandardError => e
      Rails.logger.error "Failed to get job status for #{job_id}: #{e.message}"
      nil
    end
  end

  def self.delete_status(job_id)
    return unless job_id

    begin
      Sidekiq::Status.delete(job_id)
      Rails.logger.info "Deleted job status for #{job_id}"
    rescue StandardError => e
      Rails.logger.error "Failed to delete job status for #{job_id}: #{e.message}"
    end
  end

  def self.build_status_response(job_id, status_data)
    # Parse the result if it's a JSON string
    parsed_result = status_data['result']
    if parsed_result.is_a?(String)
      begin
        parsed_result = JSON.parse(parsed_result)
      rescue JSON::ParserError => e
        Rails.logger.warn "Failed to parse job result JSON: #{e.message}"
        # Keep the original string if parsing fails
      end
    end

    {
      job_id: job_id,
      status: status_data['status'] || 'unknown',
      progress: status_data['progress'] || 0,
      result: parsed_result,
      message: status_data['message'],
      updated_at: status_data['updated_at']
    }
  end
end
