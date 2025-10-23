# frozen_string_literal: true

module Api
  module V1
    class TicketsController < ApplicationController
      before_action :authenticate_api_v1_user!
      before_action :set_ticket, only: [:show]

      def show
        render json: @ticket
      end

      def create
        @ticket = Ticket.create_with_diagnostics(
          ticket_params.merge(profile: current_api_v1_profile),
          diagnostics_params
        )

        if @ticket.persisted?
          render json: @ticket, status: :created
        else
          render json: { errors: @ticket.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_ticket
        @ticket = current_api_v1_profile.tickets.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Ticket not found' }, status: :not_found
      end

      def ticket_params
        params.require(:ticket).permit(:kind, :title, :description, :source)
      end

      def diagnostics_params
        params.permit(:app_version, :build_number, :device_model, :os_version,
                      :locale, :timezone, :network_state, :user_id)
      end
    end
  end
end
