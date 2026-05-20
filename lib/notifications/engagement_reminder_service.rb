# frozen_string_literal: true

module Notifications
  class EngagementReminderService < BaseService
    DAYS_THRESHOLD = 3

    def should_send?
      super && days_since_last_open >= DAYS_THRESHOLD
    end

    def notification_type
      'engagement_reminder'
    end

    def notification_title
      'We Miss You! 🎯'
    end

    def notification_body
      "It's been #{days_since_last_open} days. Your goals are waiting!"
    end

    def notification_data
      {
        type: 'engagement_reminder',
        screen: 'home'
      }
    end

    private

    def days_since_last_open
      reference = @profile.last_opened_app_at || @profile.created_at
      (Time.current - reference).to_i / 1.day
    end
  end
end
