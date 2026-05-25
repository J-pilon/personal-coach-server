# frozen_string_literal: true

class Notifications::ScheduleTaskRemindersJob < ApplicationJob
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

      already_notified = already_notified_task_ids(profile, day_start_utc, day_end_utc)

      tasks_due_today(profile, day_start_utc, day_end_utc, current_hour).find_each do |task|
        next if already_notified.include?(task.id)

        Notifications::TaskReminderJob.perform_later(task.id)
      end
    end
  end

  private

  def eligible_profiles
    Profile.push_notification_eligible
  end

  def tasks_due_today(profile, day_start_utc, day_end_utc, current_hour)
    profile.tasks
           .where(completed: false)
           .where(due_at: day_start_utc..day_end_utc)
           .where('EXTRACT(HOUR FROM reminder_at) <= ?', current_hour)
  end

  def already_notified_task_ids(profile, day_start_utc, day_end_utc)
    profile.notifications
           .where(notification_type: 'task_reminder')
           .where(scheduled_for: day_start_utc..day_end_utc)
           .pluck(Arel.sql("data->>'task_id'"))
           .compact
           .to_set(&:to_i)
  end
end
