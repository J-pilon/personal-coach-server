# frozen_string_literal: true

class Journal < ApplicationRecord
  belongs_to :profile
  has_many :journal_entries, dependent: :destroy

  enum :kind, { default: 'default' }

  validates :title, presence: true
  validates :kind, presence: true
  validates :profile_id, uniqueness: { scope: :kind }
end
