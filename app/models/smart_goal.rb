# frozen_string_literal: true

class SmartGoal < ApplicationRecord
  belongs_to :profile
  has_many :tasks, dependent: :nullify

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
    timeframe.humanize
  end
end
