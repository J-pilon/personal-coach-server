# frozen_string_literal: true

module Api
  module V1
    # Returns the current profile's default journal, lazily creating it
    # the first time a profile asks for it.
    class JournalsController < ApplicationController
      JOURNAL_JSON_OPTIONS = { only: %i[id title description kind created_at updated_at] }.freeze

      before_action :authenticate_api_v1_user!

      def show
        journal = DefaultJournalFinder.call(current_api_v1_profile)
        render json: journal.as_json(JOURNAL_JSON_OPTIONS)
      end
    end
  end
end
