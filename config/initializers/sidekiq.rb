# frozen_string_literal: true

require 'sidekiq'
require 'sidekiq-status'

# Configure Sidekiq server middleware
Sidekiq.configure_server do |config|
  # Configure Sidekiq::Status server middleware
  # This enables job status tracking on the server side
  Sidekiq::Status.configure_server_middleware config, expiration: 30.minutes.to_i

  # Add any other server middleware here if needed
end
