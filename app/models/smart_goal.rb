# frozen_string_literal: true

class SmartGoal < ApplicationRecord
  belongs_to :profile
  has_many :tasks, dependent: :nullify
  has_many :habits, dependent: :destroy

  validates :title, presence: true
  validates :timeframe, inclusion: { in: %w[1_month 3_months 6_months] }
  validates :specific, presence: true
  validates :measurable, presence: true
  validates :achievable, presence: true
  validates :relevant, presence: true
  validates :time_bound, presence: true
  validates :target_date, presence: true

  scope :by_timeframe, ->(timeframe) { where(timeframe: timeframe) }
  scope :completed, -> { where(completed: true) }
  scope :pending, -> { where(completed: false) }
  # Uniqueness of one primary+uncompleted goal per profile is enforced by a
  # partial unique index (see 20260714120300_add_primary_and_why_to_smart_goals).
  scope :primary, -> { where(primary: true) }

  def timeframe_display
    timeframe.humanize
  end
end
