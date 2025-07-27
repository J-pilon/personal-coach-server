# frozen_string_literal: true

# Model for storing AI service requests and their responses
# Tracks prompts, job types, and hash values for caching and analytics
class AiRequest < ApplicationRecord
  belongs_to :profile

  validates :prompt, presence: true
  validates :job_type, presence: true, inclusion: { in: %w[smart_goal prioritization task_suggestion] }
  validates :hash_value, presence: true, uniqueness: true

  before_validation :generate_hash_value, on: :create

  # Generate a hash value from the prompt string
  def generate_hash_value
    return if prompt.blank?

    self.hash_value = Digest::SHA256.hexdigest(prompt)
  end

  # Find existing request with the same prompt hash
  def self.find_by_prompt_hash(prompt_hash)
    where(hash_value: prompt_hash).first
  end

  # Check if a request with the same prompt already exists
  def self.exists_with_prompt?(prompt)
    return false if prompt.blank?

    hash_value = Digest::SHA256.hexdigest(prompt)
    exists?(hash_value: hash_value)
  end

  # Create a new AI request with automatic hash generation
  def self.create_with_prompt(profile_id:, prompt:, job_type:, status: 'pending')
    existing_request = find_by_prompt_hash(Digest::SHA256.hexdigest(prompt))

    if existing_request
      existing_request
    else
      create!(
        profile_id: profile_id,
        prompt: prompt,
        job_type: job_type,
        status: status
      )
    end
  end
end
