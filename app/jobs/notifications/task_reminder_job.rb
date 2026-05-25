# frozen_string_literal: true

class Notifications::TaskReminderJob < ApplicationJob
  queue_as :notifications

  retry_on StandardError, wait: :polynomially_longer, attempts: 2

  def perform(task_id)
    task = Task.find(task_id)
    return if task.completed?

    Notifications::TaskReminderService.new(task.profile, task: task).call
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn("TaskReminderJob: Task not found: #{task_id}")
  end
end
