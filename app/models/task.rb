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
end
