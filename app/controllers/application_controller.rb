# frozen_string_literal: true

class ApplicationController < ActionController::API

  private

  def current_api_v1_profile
    current_api_v1_user.profile
  end
end
