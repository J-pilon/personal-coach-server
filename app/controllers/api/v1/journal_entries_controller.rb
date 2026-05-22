# frozen_string_literal: true

module Api
  module V1
    # CRUD for journal entries scoped to the current profile.
    # Index supports filtering by entry_type, exact occurred_on, and
    # start_date/end_date range. The server picks the journal — clients
    # never supply profile_id or journal_id.
    class JournalEntriesController < ApplicationController
      ENTRY_JSON_OPTIONS = {
        only: %i[id journal_id profile_id title body entry_type occurred_on created_at updated_at]
      }.freeze

      before_action :authenticate_api_v1_user!
      before_action :set_entry, only: %i[show update destroy]

      def index
        scope = current_api_v1_profile.journal_entries
        scope = scope.where(entry_type: params[:entry_type]) if params[:entry_type].present?
        scope = scope.where(occurred_on: params[:occurred_on]) if params[:occurred_on].present?
        scope = scope.where(occurred_on: params[:start_date]..) if params[:start_date].present?
        scope = scope.where(occurred_on: ..params[:end_date]) if params[:end_date].present?

        @entries = scope.order(occurred_on: :desc, created_at: :desc)
        render json: @entries.as_json(ENTRY_JSON_OPTIONS)
      end

      def show
        render json: @entry.as_json(ENTRY_JSON_OPTIONS)
      end

      def create
        @entry = JournalEntries::Create.call(profile: current_api_v1_profile, params: entry_params)
        if @entry.persisted?
          render json: @entry.as_json(ENTRY_JSON_OPTIONS), status: :created
        else
          render json: { errors: @entry.errors.full_messages }, status: :unprocessable_entity
        end
      rescue ArgumentError => e
        raise e unless e.message.include?('entry_type')

        render json: { errors: ['Entry type is not included in the list'] }, status: :unprocessable_entity
      end

      def update
        if @entry.update(entry_params)
          render json: @entry.as_json(ENTRY_JSON_OPTIONS)
        else
          render json: { errors: @entry.errors.full_messages }, status: :unprocessable_entity
        end
      rescue ArgumentError => e
        raise e unless e.message.include?('entry_type')

        render json: { errors: ['Entry type is not included in the list'] }, status: :unprocessable_entity
      end

      def destroy
        @entry.destroy
        head :no_content
      end

      private

      def set_entry
        @entry = current_api_v1_profile.journal_entries.find(params[:id])
      end

      def entry_params
        params.require(:journal_entry).permit(:title, :body, :entry_type, :occurred_on)
      end
    end
  end
end
