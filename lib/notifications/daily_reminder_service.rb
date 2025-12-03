# frozen_string_literal: true

module Notifications
  class DailyReminderService < BaseService
    def notification_type
      'daily_reminder'
    end

    def notification_title
      'Stay on Track! 💪'
    end

    def notification_body
      "Can't accomplish your goal by not chipping away at it day by day"
    end

    def notification_data
      {
        type: 'daily_reminder',
        screen: 'tasks'
      }
    end
  end
end
