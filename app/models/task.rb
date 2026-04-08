# frozen_string_literal: true

class Task < ApplicationRecord
  belongs_to :profile
  belongs_to :smart_goal, optional: true

  validates :title, presence: true

  enum :action_category, {
    do: 1,
    defer: 2,
    delegate: 3
  }

  scope :incomplete, -> { where(completed: false) }
  scope :completed, -> { where(completed: true) }
  scope :by_priority, -> { order(priority: :desc) }

  def due_today?
    return false if due_at.nil? || profile.nil? || profile.timezone.blank?

    tz = ActiveSupport::TimeZone.new(profile.timezone)
    return false unless tz

    now = Time.current.in_time_zone(tz)
    due_date = due_at.in_time_zone(tz).to_date

    now.to_date == due_date
  end
end
