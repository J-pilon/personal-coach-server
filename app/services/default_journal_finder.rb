# frozen_string_literal: true

# Returns the profile's default journal, creating it on first access.
# Keeps the "one default journal per profile" invariant in one place so
# controllers and other services don't reinvent the seed defaults.
class DefaultJournalFinder
  DEFAULT_TITLE = 'My Journal'
  DEFAULT_DESCRIPTION = 'Daily journals and weekly reflections'

  def self.call(profile)
    profile.journals.find_or_create_by!(kind: 'default') do |journal|
      journal.title = DEFAULT_TITLE
      journal.description = DEFAULT_DESCRIPTION
    end
  end
end
