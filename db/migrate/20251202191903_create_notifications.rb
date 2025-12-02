# frozen_string_literal: true

class CreateNotifications < ActiveRecord::Migration[7.2]
  def change
    create_table :notifications do |t|
      t.references :profile, null: false, foreign_key: true
      t.string :notification_type, null: false
      t.string :channel, default: 'push'
      t.string :title
      t.string :body
      t.jsonb :data, default: {}
      t.string :status, default: 'pending'
      t.datetime :scheduled_for
      t.datetime :sent_at
      t.text :error_message

      t.timestamps
    end

    add_index :notifications, :notification_type
    add_index :notifications, :channel
    add_index :notifications, :status
    add_index :notifications, :scheduled_for
  end
end
