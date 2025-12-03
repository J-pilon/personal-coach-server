# frozen_string_literal: true

class Notifications::ScheduleDailyRemindersJob < ApplicationJob
  queue_as :critical

  retry_on StandardError, wait: :polynomially_longer, attempts: 2

  def perform
    eligible_profiles.find_each do |profile|
      next unless notification_time_matches?(profile)

      Notifications::DailyReminderJob.perform_later(profile.id)
    end
  end

  private

  def eligible_profiles
    Profile.push_notification_eligible
  end

  def notification_time_matches?(profile)
    pref = profile.notification_preference
    tz = ActiveSupport::TimeZone[pref.timezone]
    local_hour = Time.current.in_time_zone(tz).hour

    pref.preferred_time.hour == local_hour
  end
end
