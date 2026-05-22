# frozen_string_literal: true

module JournalEntries
  # Creates a journal entry under the profile's default journal,
  # lazily provisioning the journal on first use. Centralizes the
  # "the server decides which journal" rule so controllers never
  # accept a client-supplied journal_id.
  class Create
    def self.call(profile:, params:)
      journal = DefaultJournalFinder.call(profile)

      journal.journal_entries.create(
        profile: profile,
        title: params[:title],
        body: params[:body],
        entry_type: params[:entry_type],
        occurred_on: params[:occurred_on].presence || Date.current
      )
    end
  end
end
