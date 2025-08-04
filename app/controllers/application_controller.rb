# frozen_string_literal: true

class ApplicationController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods

  # Handle authentication errors
  rescue_from JWT::DecodeError, with: :render_unauthorized
  rescue_from JWT::ExpiredSignature, with: :render_unauthorized

  private

  def render_unauthorized
    render json: {
      status: 401,
      message: "Couldn't find an active session."
    }, status: :unauthorized
  end
end
