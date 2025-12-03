# frozen_string_literal: true

require 'sidekiq'
require 'sidekiq-status'
require 'sidekiq-cron'
require 'openssl'

Sidekiq.configure_server do |config|
  config.redis = {
    url: ENV.fetch('REDIS_URL', nil),
    ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
  }

  # Configure Sidekiq::Status server middleware
  # This enables job status tracking on the server side
  Sidekiq::Status.configure_server_middleware config, expiration: 30.minutes.to_i

  schedule_file = Rails.root.join('config', 'sidekiq_cron.yml')
  if File.exist?(schedule_file)
    Sidekiq::Cron::Job.load_from_hash(
      YAML.load_file(schedule_file),
      source: 'schedule'
    )
  end
end

Sidekiq.configure_client do |config|
  config.redis = {
    url: ENV.fetch('REDIS_URL', nil),
    ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
  }
end
