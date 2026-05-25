# frozen_string_literal: true

class Notifications::SmartGoalReminderJob < ApplicationJob
  queue_as :notifications

  retry_on StandardError, wait: :polynomially_longer, attempts: 2

  def perform(smart_goal_id)
    smart_goal = SmartGoal.find(smart_goal_id)
    return if smart_goal.completed?

    Notifications::SmartGoalReminderService.new(smart_goal.profile, smart_goal: smart_goal).call
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn("SmartGoalReminderJob: SmartGoal not found: #{smart_goal_id}")
  end
end
