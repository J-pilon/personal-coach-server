# frozen_string_literal: true

class AddReminderAtToSmartGoals < ActiveRecord::Migration[7.2]
  def change
    add_column :smart_goals, :reminder_at, :time, null: false, default: '09:00:00'
  end
end
