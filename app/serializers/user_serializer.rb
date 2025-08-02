# frozen_string_literal: true

# User serializer for JSON responses
class UserSerializer
  include JSONAPI::Serializer

  attributes :id, :email, :created_at, :updated_at

  attribute :created_date do |user|
    user.created_at&.strftime('%d/%m/%Y')
  end
end
