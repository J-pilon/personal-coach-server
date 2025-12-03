# frozen_string_literal: true

class Notifications::EngagementReminderJob < ApplicationJob
  queue_as :notifications

  retry_on StandardError, wait: :polynomially_longer, attempts: 2

  def perform(profile_id)
    profile = Profile.find(profile_id)
    Notifications::EngagementReminderService.new(profile).call
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.warn("EngagementReminderJob: Profile not found: #{profile_id}")
  end
end
