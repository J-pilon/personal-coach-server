# frozen_string_literal: true

class DiscoverySession < ApplicationRecord
  MAX_TURNS = 7

  belongs_to :profile
  belongs_to :smart_goal, optional: true

  enum :status, {
    active: 'active',
    drafted: 'drafted',
    abandoned: 'abandoned'
  }, validate: true

  validates :turn_count, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: MAX_TURNS
  }

  def append_message!(role:, text:)
    self.messages = (messages || []) + [{ 'role' => role.to_s, 'text' => text, 'turn' => next_turn_index }]
    save!
  end

  def turn_cap_reached?
    turn_count >= MAX_TURNS - 1
  end

  private

  def next_turn_index
    (messages || []).size + 1
  end
end
