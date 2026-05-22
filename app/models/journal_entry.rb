# frozen_string_literal: true

class JournalEntry < ApplicationRecord
  belongs_to :profile
  belongs_to :journal

  enum :entry_type, {
    daily_journal: 'daily_journal',
    weekly_reflection: 'weekly_reflection',
    general: 'general'
  }

  validates :body, presence: true
  validates :entry_type, presence: true
  validates :occurred_on, presence: true
end
