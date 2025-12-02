# frozen_string_literal: true

class CreateDeviceTokens < ActiveRecord::Migration[7.2]
  def change
    create_table :device_tokens do |t|
      t.references :profile, null: false, foreign_key: true

      # Token/subscription data
      t.string :token, null: false
      t.string :platform, null: false

      # For future Web Push support
      t.string :endpoint
      t.string :p256dh
      t.string :auth

      # Device metadata
      t.string :device_name
      t.string :app_version
      t.boolean :active, default: true, null: false
      t.datetime :last_used_at

      t.timestamps
    end

    add_index :device_tokens, [:profile_id, :token], unique: true
    add_index :device_tokens, :platform
    add_index :device_tokens, :active
  end
end
