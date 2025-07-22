# frozen_string_literal: true

class ApplicationController < ActionController::API

  private

  def current_user
    @current_user ||= User.first
  end

  def authenticate_user!
    # TODO
    # This would typically use JWT or session-based authentication
    # For now, we'll assume the user is authenticated via a header
    user_id = request.headers['X-User-ID']

    unless user_id && User.exists?(id: user_id)
      render json: { error: 'Authentication required' }, status: :unauthorized
      return
    end

    @current_user = User.find(user_id)
  end
end
