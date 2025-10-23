# frozen_string_literal: true

class Ticket < ApplicationRecord
  belongs_to :profile

  validates :title, presence: true, length: { maximum: 255 }
  validates :description, presence: true, length: { minimum: 10 }
  validates :kind, presence: true, inclusion: { in: %w[bug feedback] }
  validates :source, presence: true, inclusion: { in: %w[app web api] }

  scope :recent, -> { order(created_at: :desc) }
  scope :by_kind, ->(kind) { where(kind: kind) }

  def self.create_with_diagnostics(attributes, diagnostics = {})
    metadata = {
      app_version: diagnostics[:app_version],
      build_number: diagnostics[:build_number],
      device_model: diagnostics[:device_model],
      os_version: diagnostics[:os_version],
      locale: diagnostics[:locale],
      timezone: diagnostics[:timezone],
      network_state: diagnostics[:network_state],
      user_id: diagnostics[:user_id],
      timestamp: Time.current.iso8601
    }.compact

    create(attributes.merge(metadata: metadata))
  end
end
