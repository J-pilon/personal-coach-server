# frozen_string_literal: true

class DeviceToken < ApplicationRecord
  belongs_to :profile

  PLATFORMS = %w[ios android web].freeze
  STALE_AFTER = 90.days

  validates :token, presence: true
  validates :token, uniqueness: { scope: :profile_id }
  validates :platform, presence: true, inclusion: { in: PLATFORMS }

  scope :active, -> { where(active: true) }
  scope :for_platform, ->(platform) { where(platform: platform) }
  scope :push_capable, -> { where(platform: %w[ios android]) }
  scope :not_stale, -> { where('last_used_at IS NULL OR last_used_at >= ?', STALE_AFTER.ago) }

  def expo_token?
    token.start_with?('ExponentPushToken')
  end

  def web_push?
    platform == 'web' && endpoint.present?
  end

  def touch_last_used!
    # rubocop:disable Rails/SkipsModelValidations
    update_column(:last_used_at, Time.current)
    # rubocop:enable Rails/SkipsModelValidations
  end

  def deactivate!
    update!(active: false)
  end
end
