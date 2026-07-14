# frozen_string_literal: true

class CreateDiscoverySessions < ActiveRecord::Migration[7.2]
  def change
    create_table :discovery_sessions do |t|
      t.references :profile, null: false, foreign_key: true
      t.references :smart_goal, null: true, foreign_key: true
      t.jsonb :messages, default: [], null: false
      t.string :status, null: false, default: 'active'
      t.integer :turn_count, null: false, default: 0

      t.timestamps
    end
  end
end
