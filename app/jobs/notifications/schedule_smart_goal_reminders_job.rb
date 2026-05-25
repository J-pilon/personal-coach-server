# frozen_string_literal: true

class Notifications::ScheduleSmartGoalRemindersJob < ApplicationJob
  queue_as :critical

  retry_on StandardError, wait: :polynomially_longer, attempts: 2

  def perform
    eligible_profiles.find_each do |profile|
      tz = ActiveSupport::TimeZone[profile.timezone]
      next unless tz

      now_local = Time.current.in_time_zone(tz)
      day_start_utc = now_local.beginning_of_day.utc
      day_end_utc = now_local.end_of_day.utc
      current_hour = now_local.hour

      already_notified = already_notified_smart_goal_ids(profile, day_start_utc, day_end_utc)

      smart_goals_due_today(profile, day_start_utc, day_end_utc, current_hour).find_each do |smart_goal|
        next if already_notified.include?(smart_goal.id)

        Notifications::SmartGoalReminderJob.perform_later(smart_goal.id)
      end
    end
  end

  private

  def eligible_profiles
    Profile.push_notification_eligible
  end

  def smart_goals_due_today(profile, day_start_utc, day_end_utc, current_hour)
    profile.smart_goals
           .where(completed: false)
           .where(target_date: day_start_utc..day_end_utc)
           .where('EXTRACT(HOUR FROM reminder_at) <= ?', current_hour)
  end

  def already_notified_smart_goal_ids(profile, day_start_utc, day_end_utc)
    profile.notifications
           .where(notification_type: 'smart_goal_reminder')
           .where(scheduled_for: day_start_utc..day_end_utc)
           .pluck(Arel.sql("data->>'smart_goal_id'"))
           .compact
           .to_set(&:to_i)
  end
end
