# frozen_string_literal: true

class Notification < ApplicationRecord
  belongs_to :profile
  belongs_to :device_token, optional: true # For push, tracks which device

  TYPES = %w[daily_reminder engagement_reminder task_reminder].freeze
  STATUSES = %w[pending sent failed].freeze
  CHANNELS = %w[push email sms].freeze

  validates :status, inclusion: { in: STATUSES }
  validates :notification_type, inclusion: { in: TYPES }
  validates :channel, inclusion: { in: CHANNELS }

  scope :pending, -> { where(status: 'pending') }
  scope :sent, -> { where(status: 'sent') }
  scope :failed, -> { where(status: 'failed') }
  scope :by_channel, ->(channel) { where(channel: channel) }
end
