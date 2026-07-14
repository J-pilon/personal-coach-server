# frozen_string_literal: true

module Api
  module V1
    module Onboarding
      module Discovery
        class SessionsController < ApplicationController
          before_action :authenticate_api_v1_user!

          def create
            session = current_api_v1_profile.discovery_sessions.create!

            ai_request = AiRequest.create!(
              profile: current_api_v1_profile,
              prompt: '[pending onboarding_goal_discovery prompt]',
              job_type: 'onboarding_goal_discovery',
              status: 'pending'
            )

            job = OnboardingDiscoveryJob.perform_later(
              discovery_session_id: session.id,
              ai_request_id: ai_request.id
            )

            render json: {
              session_id: session.id,
              ai_request_id: ai_request.id,
              job_id: job.provider_job_id,
              status: 'queued'
            }, status: :created
          end
        end
      end
    end
  end
end
