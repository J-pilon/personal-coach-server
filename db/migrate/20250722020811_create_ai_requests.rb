# frozen_string_literal: true

class CreateAiRequests < ActiveRecord::Migration[7.1]
  def change
    create_table :ai_requests do |t|
      t.text :prompt, null: false
      t.string :job_type, null: false
      t.string :hash_value, null: false
      t.string :status, null: false
      t.text :error_message
      t.references :profile, null: false, foreign_key: true

      t.timestamps
    end

    add_index :ai_requests, :hash_value
    add_index :ai_requests, :job_type
  end
end
