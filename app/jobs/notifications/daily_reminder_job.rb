# frozen_string_literal: true

class Notifications::DailyReminderJob < ApplicationJob
  queue_as :notifications

  retry_on StandardError, wait: :polynomially_longer, attempts: 2

  def perform(profile_id)
    profile = Profile.find(profile_id)
    Notifications::DailyReminderService.new(profile).call
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn("DailyReminderJob: Profile not found: #{profile_id}")
  end
end
