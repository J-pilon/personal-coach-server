# frozen_string_literal: true

class NotificationSchedule < ApplicationRecord
  belongs_to :profile

  enum :kind, { daily_check_in: 'daily_check_in' }, validate: true

  validates :local_time, presence: true
  validates :timezone, presence: true
  validate :timezone_must_be_recognized

  private

  def timezone_must_be_recognized
    return if timezone.blank?
    return if ActiveSupport::TimeZone[timezone].present?

    errors.add(:timezone, 'is not a recognized IANA timezone')
  end
end
