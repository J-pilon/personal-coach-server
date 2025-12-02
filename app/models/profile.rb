# frozen_string_literal: true

class Profile < ApplicationRecord
  belongs_to :user

  has_many :smart_goals, dependent: :destroy
  has_many :tasks, dependent: :destroy
  has_many :ai_requests, dependent: :destroy
  has_many :tickets, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :device_tokens, dependent: :destroy
  has_one :notification_preference, dependent: :destroy

  validates :onboarding_status, inclusion: { in: %w[incomplete complete] }

  after_create :create_notification_preference

  delegate :push_enabled?, :email_enabled?, :sms_enabled?,
           :timezone, :preferred_time, :in_quiet_hours?,
           :last_opened_app_at, to: :notification_preference, allow_nil: true

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

  def active_device_tokens
    device_tokens.active
  end

  def push_tokens
    device_tokens.active.push_capable
  end

  def push_notifications_enabled?
    notification_preference&.push_enabled? && push_tokens.exists?
  end

  def record_app_open!
    notification_preference&.update!(last_opened_app_at: Time.current)
  end

  private

  def create_notification_preference
    build_notification_preference.save!
  end
end
