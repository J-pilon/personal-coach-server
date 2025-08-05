# frozen_string_literal: true

# User model for authentication
# Handles user authentication with email and password
# Has one profile for user details and many tasks/smart_goals
class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  devise :database_authenticatable, :registerable, :recoverable,
         :validatable, :jwt_authenticatable, jwt_revocation_strategy: self

  self.skip_session_storage = [:http_auth, :params_auth]

  has_one :profile, dependent: :destroy

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password_confirmation, presence: true, on: :create

  after_create :create_profile

  def jwt_payload
    {
      'jti' => jti,
      'sub' => jwt_subject,
      'user_id' => id,
      'scp' => 'api_v1_user'
    }
  end

  def jwt_subject
    id
  end

  private

  def create_profile
    build_profile.save!
  end
end
