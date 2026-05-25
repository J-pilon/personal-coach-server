# frozen_string_literal: true

module Notifications
  class SmartGoalReminderService < BaseService
    def initialize(profile, smart_goal:, channels: nil)
      super(profile, channels: channels)
      @smart_goal = smart_goal
    end

    def notification_type
      'smart_goal_reminder'
    end

    def notification_title
      'Goal target date today 🎯'
    end

    def notification_body
      @smart_goal.title
    end

    def notification_data
      {
        type: 'smart_goal_reminder',
        screen: 'smartGoalDetail',
        smart_goal_id: @smart_goal.id
      }
    end
  end
end
