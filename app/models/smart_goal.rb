# frozen_string_literal: true

class SmartGoal < ApplicationRecord
  belongs_to :profile

  validates :title, presence: true
  validates :timeframe, inclusion: { in: %w[1_month 3_months 6_months] }
  validates :specific, presence: true
  validates :measurable, presence: true
  validates :achievable, presence: true
  validates :relevant, presence: true
  validates :time_bound, presence: true

  scope :by_timeframe, ->(timeframe) { where(timeframe: timeframe) }
  scope :completed, -> { where(completed: true) }
  scope :pending, -> { where(completed: false) }

  def timeframe_display
    case timeframe
    when '1_month'
      '1 Month'
    when '3_months'
      '3 Months'
    when '6_months'
      '6 Months'
    end
  end
end
