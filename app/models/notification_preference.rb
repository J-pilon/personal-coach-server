# frozen_string_literal: true

class NotificationPreference < ApplicationRecord
  belongs_to :profile

  validates :timezone, presence: true

  def push_enabled?
    push_enabled
  end

  def email_enabled?
    email_enabled
  end

  def sms_enabled?
    sms_enabled
  end

  # Check if a specific channel is enabled for a notification type
  # Supports future granular per-type settings via channel_settings JSON column
  def channel_enabled?(_notification_type, channel)
    case channel.to_sym
    when :push then push_enabled?
    when :email then email_enabled?
    when :sms then sms_enabled?
    else false
    end
  end

  def in_quiet_hours?(time = Time.current)
    return false unless quiet_hours_start && quiet_hours_end

    current_time = time.in_time_zone(timezone).strftime('%H:%M')
    start_time = quiet_hours_start.strftime('%H:%M')
    end_time = quiet_hours_end.strftime('%H:%M')

    if start_time < end_time
      current_time >= start_time && current_time < end_time
    else
      current_time >= start_time || current_time < end_time
    end
  end
end
