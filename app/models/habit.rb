# frozen_string_literal: true

class Habit < ApplicationRecord
  belongs_to :profile
  belongs_to :smart_goal
  has_many :habit_completions, dependent: :destroy

  enum :frequency, {
    daily: 'daily',
    weekdays: 'weekdays',
    weekly_n_times: 'weekly_n_times',
    custom: 'custom'
  }, validate: true

  # Frequencies a user can pick through the API. The rest stay valid in the schema.
  USER_SELECTABLE_FREQUENCIES = %w[daily weekdays].freeze

  validates :title, :cue, :minimum_version, :normal_version, presence: true
  validates :position, inclusion: { in: 1..3 }

  scope :active, -> { where(archived_at: nil) }

  def archived?
    archived_at.present?
  end
end
