# frozen_string_literal: true

require 'sidekiq'
require 'sidekiq-status'
require 'openssl'

Sidekiq.configure_server do |config|
  config.redis = {
    url: ENV['REDIS_URL'],
    ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
  }

  # Configure Sidekiq::Status server middleware
  # This enables job status tracking on the server side
  Sidekiq::Status.configure_server_middleware config, expiration: 30.minutes.to_i
end

Sidekiq.configure_client do |config|
  config.redis = {
    url: ENV['REDIS_URL'],
    ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
  }
end
