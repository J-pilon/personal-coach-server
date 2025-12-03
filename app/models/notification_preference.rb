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
