# frozen_string_literal: true

module Notifications
  class TaskReminderService < BaseService
    def initialize(profile, task:, channels: nil)
      super(profile, channels: channels)
      @task = task
    end

    def notification_type
      'task_reminder'
    end

    def notification_title
      'Task due today 📌'
    end

    def notification_body
      @task.title
    end

    def notification_data
      {
        type: 'task_reminder',
        screen: 'taskDetail',
        task_id: @task.id
      }
    end
  end
end
