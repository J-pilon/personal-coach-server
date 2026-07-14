# frozen_string_literal: true

class HabitCompletion < ApplicationRecord
  class InvalidTransitionError < StandardError; end

  belongs_to :habit

  enum :state, {
    committed: 'committed',
    completed_minimum: 'completed_minimum',
    completed_normal: 'completed_normal',
    skipped: 'skipped'
  }, validate: true, prefix: :state

  validates :completed_on, presence: true

  TRANSITIONS = {
    'committed' => %w[completed_minimum completed_normal skipped]
  }.freeze

  COMPLETED_STATES = %w[completed_minimum completed_normal].freeze

  def transition_to!(new_state)
    new_state = new_state.to_s
    allowed = TRANSITIONS[state] || []
    unless allowed.include?(new_state)
      raise InvalidTransitionError, "cannot transition from #{state.inspect} to #{new_state.inspect}"
    end

    self.state = new_state
    self.completed_at = Time.current if COMPLETED_STATES.include?(new_state)
    save!
  end
end
