# frozen_string_literal: true

class CreateJournalEntries < ActiveRecord::Migration[7.2]
  def change
    create_table :journal_entries do |t|
      t.references :profile, null: false, foreign_key: true
      t.references :journal, null: false, foreign_key: true
      t.string :title
      t.text :body, null: false
      t.string :entry_type, null: false
      t.date :occurred_on, null: false

      t.timestamps
    end

    add_index :journal_entries, %i[profile_id occurred_on]
    add_index :journal_entries, %i[profile_id entry_type]
  end
end
