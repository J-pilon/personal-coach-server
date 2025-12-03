# frozen_string_literal: true

class CreateNotificationPreferences < ActiveRecord::Migration[7.2]
  def change
    create_table :notification_preferences do |t|
      t.references :profile, null: false, foreign_key: true

      # Channel toggles
      t.boolean :push_enabled, default: true, null: false
      t.boolean :email_enabled, default: true, null: false
      t.boolean :sms_enabled, default: false, null: false

      # Scheduling
      t.time :preferred_time, default: '09:00'
      t.string :timezone, default: 'UTC'

      # Scheduling
      t.time :quiet_hours_start
      t.time :quiet_hours_end

      # Granular controls
      # Store as JSON for flexibility without schema changes
      t.jsonb :channel_settings
      # Example: { "daily_reminder": { "push": true, "email": false } }

      t.datetime :last_opened_app_at

      t.timestamps
    end
  end
end
