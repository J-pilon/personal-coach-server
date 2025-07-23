# frozen_string_literal: true

class Profile < ApplicationRecord
  belongs_to :user

  has_many :smart_goals, dependent: :destroy
  has_many :tasks, dependent: :destroy
  has_many :ai_requests, dependent: :destroy

  validates :onboarding_status, inclusion: { in: %w[incomplete complete] }

  def incomplete_tasks
    tasks.where(completed: false)
  end

  def recent_incomplete_tasks(max_tasks = 5)
    incomplete_tasks.order(created_at: :desc).limit(max_tasks)
  end

  def pending_smart_goals(max_goals = 3)
    smart_goals.pending.order(created_at: :desc).limit(max_goals)
  end

  def onboarding_complete?
    onboarding_status == 'complete'
  end

  def complete_onboarding!
    update!(
      onboarding_status: 'complete',
      onboarding_completed_at: Time.current
    )
  end

  def full_name
    [first_name, last_name].compact.join(' ')
  end
end
