# frozen_string_literal: true

class AiProcessingJob < ApplicationJob
  queue_as :ai_processing

  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  private

  def log_error(error, context = {})
    Rails.logger.error "AI Processing Job Error: #{error.message}"
    Rails.logger.error "Context: #{context}"
    Rails.logger.error "Backtrace: #{error.backtrace&.first(5)&.join("\n") || 'No backtrace available'}"
  end

  def update_ai_request_status(ai_request, status, error_message = nil)
    ai_request.update(
      status: status,
      error_message: error_message,
      completed_at: Time.current
    )
  rescue StandardError => e
    Rails.logger.error "Failed to update AI request status: #{e.message}"
  end
end
