# frozen_string_literal: true

class Notifications::ScheduleEngagementRemindersJob < ApplicationJob
  queue_as :critical

  INACTIVE_DAYS_THRESHOLD = Notifications::EngagementReminderService::DAYS_THRESHOLD

  def perform
    eligible_profiles.find_each do |profile|
      Notifications::EngagementReminderService.new(profile).call
    end
  end

  private

  def eligible_profiles
    Profile.push_notification_eligible.inactive_for_days(INACTIVE_DAYS_THRESHOLD)
  end
end
