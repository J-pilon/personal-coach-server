# frozen_string_literal: true

class MoveTimezoneFromNotificationPreferencesToProfiles < ActiveRecord::Migration[7.2]
  def up
    # Add timezone column to profiles
    add_column :profiles, :timezone, :string, default: 'UTC'

    # Copy timezone values from notification_preferences to profiles
    execute <<-SQL.squish
      UPDATE profiles
      SET timezone = notification_preferences.timezone
      FROM notification_preferences
      WHERE profiles.id = notification_preferences.profile_id
    SQL

    # Remove timezone column from notification_preferences
    remove_column :notification_preferences, :timezone
  end

  def down
    # Add timezone column back to notification_preferences
    add_column :notification_preferences, :timezone, :string, default: 'UTC'

    # Copy timezone values back from profiles to notification_preferences
    execute <<-SQL.squish
      UPDATE notification_preferences
      SET timezone = profiles.timezone
      FROM profiles
      WHERE notification_preferences.profile_id = profiles.id
    SQL

    # Remove timezone column from profiles
    remove_column :profiles, :timezone
  end
end
