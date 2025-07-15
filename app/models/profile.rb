# frozen_string_literal: true

class Profile < ApplicationRecord
  belongs_to :user

  has_many :smart_goals, dependent: :destroy
  has_many :tasks, dependent: :destroy

  validates :onboarding_status, inclusion: { in: %w[incomplete complete] }

  def onboarding_complete?
    onboarding_status == 'complete'
  end

  def complete_onboarding!
    update!(
      onboarding_status: 'complete',
      onboarding_completed_at: Time.current
    )
  end

  def full_name
    [first_name, last_name].compact.join(' ')
  end
end
