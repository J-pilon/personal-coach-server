# frozen_string_literal: true

class CreateJournals < ActiveRecord::Migration[7.2]
  def change
    create_table :journals do |t|
      t.references :profile, null: false, foreign_key: true
      t.string :title, null: false
      t.string :description
      t.string :kind, null: false, default: 'default'

      t.timestamps
    end

    add_index :journals, %i[profile_id kind], unique: true
  end
end
