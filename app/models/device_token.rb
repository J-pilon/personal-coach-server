# frozen_string_literal: true

class DeviceToken < ApplicationRecord
  belongs_to :profile

  PLATFORMS = %w[ios android web].freeze

  validates :token, presence: true
  validates :token, uniqueness: { scope: :profile_id }
  validates :platform, presence: true, inclusion: { in: PLATFORMS }

  scope :active, -> { where(active: true) }
  scope :for_platform, ->(platform) { where(platform: platform) }
  scope :push_capable, -> { where(platform: %w[ios android]) }

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
